import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tether/features/achievements/achievements_screen.dart';
import 'package:tether/features/settings/settings_screen.dart';
import 'package:tether/features/special_dates/special_dates_screen.dart';
import 'package:tether/features/drawing/drawing_canvas_screen.dart';
import 'package:tether/features/photo_memory/photo_memory_screen.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../core/services/mood_service.dart';
import '../../core/services/quick_message_service.dart';
import '../../core/services/achievement_service.dart';
import '../../core/services/relationship_service.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/mood_picker.dart';
import '../../shared/widgets/message_overlay.dart';
import '../../shared/widgets/gesture_picker.dart';
import '../../shared/widgets/heartbeat_button.dart';
import '../../models/gesture_type.dart';

/// Canvas overlay with action bar and status indicators
class CanvasOverlay extends StatefulWidget {
  final bool isConnected;
  final bool isPartnerOnline;
  final VoidCallback? onSendGesture;
  final Function(GestureType)? onGestureSelected;

  const CanvasOverlay({
    super.key,
    required this.isConnected,
    required this.isPartnerOnline,
    this.onSendGesture,
    this.onGestureSelected,
  });

  @override
  State<CanvasOverlay> createState() => _CanvasOverlayState();
}

class _CanvasOverlayState extends State<CanvasOverlay> {
  MessageEvent? _currentMessage;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _messageSubscription = QuickMessageService.instance.incomingMessages.listen(
      _handleIncomingMessage,
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _handleIncomingMessage(MessageEvent event) {
    if (event.isFromPartner) {
      setState(() => _currentMessage = event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top status bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Left side: Connection status only (compact)
                  _buildConnectionDot(),
                  const SizedBox(width: 12),
                  // Days counter
                  _buildDaysCounter(),
                  const SizedBox(width: 12),
                  // Partner Mood
                  _buildPartnerMoodBadge(),
                  const Spacer(),
                  // Right side: Achievement icon + settings
                  _buildAchievementBadge(),
                  const SizedBox(width: 8),
                  _buildSettingsButton(context),
                ],
              ),
            ),
          ),
        ),

        // Message overlay
        if (_currentMessage != null)
          MessageOverlay(
            message: _currentMessage!,
            onComplete: () => setState(() => _currentMessage = null),
          ),

        // Bottom action bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildActionBar(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionDot() {
    final isOnline = widget.isConnected && widget.isPartnerOnline;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        shape: BoxShape.circle,
        border: Border.all(
          color: (isOnline ? AppColors.success : AppColors.warning).withValues(
            alpha: 0.5,
          ),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? AppColors.success : AppColors.warning)
                .withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline ? AppColors.success : AppColors.warning,
            boxShadow: [
              BoxShadow(
                color: (isOnline ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.6),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaysCounter() {
    return ListenableBuilder(
      listenable: RelationshipService.instance,
      builder: (context, _) {
        final days = RelationshipService.instance.daysTogether;
        final hasDate = RelationshipService.instance.hasStartDate;

        return GestureDetector(
          onTap: () => _showDatePicker(context),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            borderRadius: 16,
            enableGlow: false,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite,
                  size: 14,
                  color: hasDate ? AppColors.loveRed : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  hasDate ? '$days days' : 'Set date',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: hasDate
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final currentDate =
        RelationshipService.instance.startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await RelationshipService.instance.setStartDate(picked);
      HapticFeedback.lightImpact();
    }
  }

  Widget _buildPartnerMoodBadge() {
    return ListenableBuilder(
      listenable: MoodService.instance,
      builder: (context, _) {
        final mood = MoodService.instance.partnerMood;
        if (mood == null) return const SizedBox.shrink();

        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          borderRadius: 16,
          enableGlow: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mood.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                mood.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementBadge() {
    return ListenableBuilder(
      listenable: AchievementService.instance,
      builder: (context, _) {
        final level = AchievementService.instance.currentLevel;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AchievementsScreen()),
            );
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(level.emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.settings_outlined,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Drawing
          _buildDockItem(
            context,
            icon: Icons.brush_rounded,
            label: 'Draw',
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DrawingCanvasScreen()),
            ),
          ),

          // 2. Memories
          _buildDockItem(
            context,
            icon: Icons.photo_library_rounded,
            label: 'Memories',
            color: Colors.amber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PhotoMemoryScreen()),
            ),
          ),

          // 3. Heartbeat (Center)
          Transform.translate(
            offset: const Offset(0, -6),
            child: const HeartbeatButton(size: 60), // Slightly larger
          ),

          // 4. Dates
          _buildDockItem(
            context,
            icon: Icons.calendar_month_rounded,
            label: 'Dates',
            color: AppColors.highFiveGold,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SpecialDatesScreen()),
            ),
          ),

          // 5. Menu
          _buildDockItem(
            context,
            icon: Icons.grid_view_rounded,
            label: 'Menu',
            color: AppColors.textSecondary,
            onTap: () => _showQuickActions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDockItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Send Love ❤️',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickActionItem(
                    icon: Icons.emoji_emotions_outlined,
                    label: 'Mood',
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.pop(context);
                      _showMoodPicker(context);
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.favorite,
                    label: 'Gesture',
                    color: AppColors.loveRed,
                    onTap: () {
                      Navigator.pop(context);
                      _showGesturePicker(context);
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.message_rounded,
                    label: 'Message',
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _showMessagePicker(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMoodPicker(BuildContext context) async {
    HapticFeedback.lightImpact();
    final mood = await MoodPicker.show(
      context,
      currentMood: MoodService.instance.myMood,
    );
    if (mood != null) {
      await MoodService.instance.setMood(mood);
    }
  }

  Future<void> _showGesturePicker(BuildContext context) async {
    HapticFeedback.lightImpact();
    final gesture = await GesturePicker.show(context);
    if (gesture != null) {
      widget.onGestureSelected?.call(gesture);
    }
  }

  Future<void> _showMessagePicker(BuildContext context) async {
    HapticFeedback.lightImpact();
    final result = await QuickMessagePicker.show(context);

    if (result != null) {
      if (result is QuickMessage) {
        await QuickMessageService.instance.sendMessage(result);
        setState(() {
          _currentMessage = MessageEvent.preset(
            message: result,
            timestamp: DateTime.now(),
            isFromPartner: false,
          );
        });
      } else if (result is String) {
        await QuickMessageService.instance.sendCustomMessage(result);
        setState(() {
          _currentMessage = MessageEvent.custom(
            text: result,
            timestamp: DateTime.now(),
            isFromPartner: false,
          );
        });
      }
    }
  }
}
