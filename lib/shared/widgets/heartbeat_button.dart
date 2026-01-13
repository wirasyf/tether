import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../core/services/heartbeat_service.dart';

/// Heartbeat sharing button with animated heart
class HeartbeatButton extends StatefulWidget {
  const HeartbeatButton({super.key});

  @override
  State<HeartbeatButton> createState() => _HeartbeatButtonState();
}

class _HeartbeatButtonState extends State<HeartbeatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHeartbeat() {
    HapticFeedback.heavyImpact();
    _controller.repeat();

    // Start continuous heartbeat sharing
    HeartbeatService.instance.startSharing();

    // Timer to send pulses at heartbeat rate (~72 bpm = ~830ms)
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
    _controller.stop();
    _controller.reset();
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
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.loveRed.withValues(alpha: 0.3),
                  AppColors.loveRed.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isPressed
                        ? _scaleAnimation.value
                        : (isReceiving ? 1.1 : 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '❤️',
                          style: TextStyle(fontSize: _isPressed ? 42 : 36),
                        ),
                        if (isReceiving && !_isPressed)
                          Text(
                            '${HeartbeatService.instance.partnerBpm} bpm',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.loveRed,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
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
