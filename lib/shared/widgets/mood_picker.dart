import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/mood_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_card.dart';

/// Beautiful mood picker bottom sheet
class MoodPicker extends StatelessWidget {
  final MoodType? currentMood;
  final Function(MoodType) onMoodSelected;

  const MoodPicker({super.key, this.currentMood, required this.onMoodSelected});

  static Future<MoodType?> show(BuildContext context, {MoodType? currentMood}) {
    return showModalBottomSheet<MoodType>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MoodPicker(
        currentMood: currentMood,
        onMoodSelected: (mood) => Navigator.pop(context, mood),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface.withValues(alpha: 0.95),
            AppColors.background,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mood, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'How are you feeling?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Share your mood with your partner',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 32),

              // Mood grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: MoodType.values.length,
                itemBuilder: (context, index) {
                  final mood = MoodType.values[index];
                  final isSelected = currentMood == mood;

                  return _MoodItem(
                    mood: mood,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onMoodSelected(mood);
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              // Clear mood button
              if (currentMood != null)
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    MoodService.instance.clearMood();
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.close, size: 18, color: AppColors.textMuted),
                  label: Text(
                    'Clear Mood',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodItem extends StatefulWidget {
  final MoodType mood;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodItem({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_MoodItem> createState() => _MoodItemState();
}

class _MoodItemState extends State<_MoodItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.mood.primaryColorValue);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? color.withValues(alpha: 0.2)
                    : AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSelected
                      ? color
                      : Colors.white.withValues(alpha: 0.1),
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: -2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.mood.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 6),
                  Text(
                    widget.mood.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: widget.isSelected
                          ? color
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widget to display partner's mood on canvas
class PartnerMoodIndicator extends StatelessWidget {
  final MoodType mood;
  final DateTime? timestamp;

  const PartnerMoodIndicator({super.key, required this.mood, this.timestamp});

  String get _timeAgo {
    if (timestamp == null) return '';
    final diff = DateTime.now().difference(timestamp!);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(mood.primaryColorValue);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(mood.emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Partner feels ${mood.displayName.toLowerCase()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              if (timestamp != null)
                Text(
                  _timeAgo,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
