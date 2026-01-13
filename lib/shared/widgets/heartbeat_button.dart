import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../core/services/heartbeat_service.dart';

/// Heartbeat sharing button with animated heart and glowing effects
class HeartbeatButton extends StatefulWidget {
  const HeartbeatButton({super.key});

  @override
  State<HeartbeatButton> createState() => _HeartbeatButtonState();
}

class _HeartbeatButtonState extends State<HeartbeatButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _pressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pressAnimation;

  bool _isPressed = false;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();

    // Continuous pulse animation (heartbeat effect)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
    ]).animate(_pulseController);
    _pulseController.repeat();

    // Glow animation for the outer rings
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);

    // Press animation
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _pressController.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHeartbeat() {
    HapticFeedback.heavyImpact();
    _pressController.forward();

    // Faster pulse when pressing
    _pulseController.duration = const Duration(milliseconds: 600);
    _pulseController.repeat();

    HeartbeatService.instance.startSharing();

    _holdTimer = Timer.periodic(const Duration(milliseconds: 830), (_) {
      if (_isPressed) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) HapticFeedback.lightImpact();
        });
      }
    });
  }

  void _stopHeartbeat() {
    _pressController.reverse();
    _pulseController.duration = const Duration(milliseconds: 1200);
    _pulseController.repeat();
    _holdTimer?.cancel();
    HeartbeatService.instance.stopSharing();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HeartbeatService.instance,
      builder: (context, _) {
        final isReceiving = HeartbeatService.instance.isReceiving;

        return GestureDetector(
          onTapDown: (_) {
            setState(() => _isPressed = true);
            _startHeartbeat();
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _stopHeartbeat();
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
            _stopHeartbeat();
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _pulseAnimation,
              _glowAnimation,
              _pressAnimation,
            ]),
            builder: (context, child) {
              return Transform.scale(
                scale: _pressAnimation.value,
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring 3
                      Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.loveRed.withValues(
                              alpha: _glowAnimation.value * 0.2,
                            ),
                            width: 1,
                          ),
                        ),
                      ),

                      // Outer glow ring 2
                      Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.loveRed.withValues(
                              alpha: _glowAnimation.value * 0.3,
                            ),
                            width: 1.5,
                          ),
                        ),
                      ),

                      // Outer glow ring 1
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.loveRed.withValues(
                                alpha: _isPressed ? 0.4 : 0.2,
                              ),
                              AppColors.loveRed.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),

                      // Main heart container
                      Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.loveRed.withValues(
                                  alpha: _isPressed ? 0.5 : 0.3,
                                ),
                                AppColors.loveRed.withValues(
                                  alpha: _isPressed ? 0.3 : 0.15,
                                ),
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.loveRed.withValues(
                                alpha: _isPressed ? 0.8 : 0.5,
                              ),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.loveRed.withValues(
                                  alpha: _isPressed ? 0.6 : 0.3,
                                ),
                                blurRadius: _isPressed ? 25 : 15,
                                spreadRadius: _isPressed ? 5 : 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '❤️',
                              style: TextStyle(fontSize: _isPressed ? 28 : 24),
                            ),
                          ),
                        ),
                      ),

                      // BPM indicator when receiving
                      if (isReceiving && !_isPressed)
                        Positioned(
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.loveRed.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              '${HeartbeatService.instance.partnerBpm} ❤️',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.loveRed,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Heartbeat received overlay animation
class HeartbeatReceivedOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const HeartbeatReceivedOverlay({super.key, required this.onComplete});

  @override
  State<HeartbeatReceivedOverlay> createState() =>
      _HeartbeatReceivedOverlayState();
}

class _HeartbeatReceivedOverlayState extends State<HeartbeatReceivedOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.5,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 20),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 150), () {
      HapticFeedback.lightImpact();
    });

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.loveRed.withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('❤️', style: TextStyle(fontSize: 72)),
                    const SizedBox(height: 12),
                    Text(
                      'Partner\'s Heartbeat',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
