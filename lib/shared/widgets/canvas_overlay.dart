import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tether/features/achievements/achievements_screen.dart';
import 'package:tether/features/settings/settings_screen.dart';
import 'package:tether/features/special_dates/special_dates_screen.dart';
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildConnectionStatus(),
                  const SizedBox(width: 8),
                  _buildDaysCounter(),
                  const Spacer(),
                  _buildPartnerMood(),
                  const SizedBox(width: 12),
                  _buildSettingsButton(context),
                ],
              ),
            ),
          ),
        ),

        // Partner mood indicator
        if (MoodService.instance.partnerMood != null)
          Positioned(
            top: 80,
            left: 16,
            child: PartnerMoodIndicator(
              mood: MoodService.instance.partnerMood!,
              timestamp: MoodService.instance.partnerMoodTime,
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

  Widget _buildConnectionStatus() {
    final isOnline = widget.isConnected && widget.isPartnerOnline;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 20,
      enableGlow: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? AppColors.success : AppColors.warning,
              boxShadow: [
                BoxShadow(
                  color: (isOnline ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isOnline ? 'Partner Online' : 'Partner Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isOnline ? AppColors.success : AppColors.textMuted,
            ),
          ),
        ],
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

  Widget _buildPartnerMood() {
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
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            borderRadius: 16,
            enableGlow: false,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(level.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  level.displayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(Icons.settings, color: AppColors.textSecondary, size: 20),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      borderRadius: 28,
      enableGlow: false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.mood,
            label: 'Mood',
            onTap: () => _showMoodPicker(context),
          ),
          // Heartbeat button
          const HeartbeatButton(),
          _buildActionButton(
            icon: Icons.favorite,
            label: 'Gesture',
            color: AppColors.loveRed,
            onTap: () => _showGesturePicker(context),
          ),
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Message',
            onTap: () => _showMessagePicker(context),
          ),
          _buildActionButton(
            icon: Icons.calendar_today,
            label: 'Dates',
            onTap: () => _showSpecialDates(context),
          ),
        ],
      ),
    );
  }

  void _showSpecialDates(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SpecialDatesScreen()),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? AppColors.textSecondary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color ?? AppColors.textMuted,
              ),
            ),
          ],
        ),
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
