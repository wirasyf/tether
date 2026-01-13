import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/gesture_type.dart';
import '../../core/theme/app_colors.dart';

/// Gesture picker with all available gestures
class GesturePicker extends StatelessWidget {
  final Function(GestureType) onGestureSelected;

  const GesturePicker({super.key, required this.onGestureSelected});

  static Future<GestureType?> show(BuildContext context) {
    return showModalBottomSheet<GestureType>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GesturePicker(
        onGestureSelected: (gesture) => Navigator.pop(context, gesture),
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
                  Icon(Icons.gesture, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Send a Gesture',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Express yourself with meaningful gestures',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 24),

              // Gestures grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: GestureType.values.length,
                itemBuilder: (context, index) {
                  final gesture = GestureType.values[index];
                  return _GestureItem(
                    gesture: gesture,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onGestureSelected(gesture);
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _GestureItem extends StatefulWidget {
  final GestureType gesture;
  final VoidCallback onTap;

  const _GestureItem({required this.gesture, required this.onTap});

  @override
  State<_GestureItem> createState() => _GestureItemState();
}

class _GestureItemState extends State<_GestureItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  GestureEvent get _tempGesture =>
      GestureEvent.create(type: widget.gesture, x: 0.5, y: 0.5);

  @override
  Widget build(BuildContext context) {
    final color = Color(_tempGesture.colorValue);

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
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _tempGesture.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tempGesture.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color,
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
