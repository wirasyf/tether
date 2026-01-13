import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';

/// Animated connection status with pulse effect
class ConnectionPulse extends StatefulWidget {
  final bool isConnected;
  final bool isPartnerOnline;
  final String? partnerName;
  final DateTime? lastActive;

  const ConnectionPulse({
    super.key,
    required this.isConnected,
    required this.isPartnerOnline,
    this.partnerName,
    this.lastActive,
  });

  @override
  State<ConnectionPulse> createState() => _ConnectionPulseState();
}

class _ConnectionPulseState extends State<ConnectionPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.8,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    if (widget.isPartnerOnline) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(ConnectionPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPartnerOnline && !oldWidget.isPartnerOnline) {
      _pulseController.repeat();
    } else if (!widget.isPartnerOnline && oldWidget.isPartnerOnline) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getLastActiveText() {
    if (widget.lastActive == null) return '';

    final diff = DateTime.now().difference(widget.lastActive!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.isConnected && widget.isPartnerOnline;
    final statusColor = isOnline ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulse indicator
          Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring
              if (isOnline)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) {
                    return Container(
                      width: 16 * _pulseAnimation.value,
                      height: 16 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withValues(
                          alpha: 0.3 * (1 - (_pulseAnimation.value - 1) / 0.8),
                        ),
                      ),
                    );
                  },
                ),
              // Solid dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(width: 10),

          // Status text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.partnerName ??
                    (isOnline ? 'Partner Online' : 'Partner Offline'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isOnline
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              if (!isOnline && widget.lastActive != null)
                Text(
                  _getLastActiveText(),
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Floating hearts animation widget
class FloatingHearts extends StatefulWidget {
  final int count;
  final Duration duration;

  const FloatingHearts({
    super.key,
    this.count = 5,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<FloatingHearts> createState() => _FloatingHeartsState();
}

class _FloatingHeartsState extends State<FloatingHearts>
    with TickerProviderStateMixin {
  final List<_HeartData> _hearts = [];
  Timer? _spawnTimer;

  @override
  void initState() {
    super.initState();
    _spawnHeart();
    _spawnTimer = Timer.periodic(
      Duration(milliseconds: widget.duration.inMilliseconds ~/ widget.count),
      (_) => _spawnHeart(),
    );
  }

  void _spawnHeart() {
    if (!mounted) return;

    final controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    final heart = _HeartData(
      x: 0.2 + (DateTime.now().millisecond % 60) / 100,
      controller: controller,
    );

    setState(() => _hearts.add(heart));

    controller.forward().then((_) {
      if (mounted) {
        setState(() => _hearts.remove(heart));
        controller.dispose();
      }
    });
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    for (final heart in _hearts) {
      heart.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _hearts.map((heart) {
        return AnimatedBuilder(
          animation: heart.controller,
          builder: (context, _) {
            final progress = heart.controller.value;
            final size = MediaQuery.of(context).size;

            return Positioned(
              left: size.width * heart.x,
              bottom: size.height * progress * 0.5,
              child: Opacity(
                opacity: 1 - progress,
                child: Transform.scale(
                  scale: 0.5 + progress * 0.5,
                  child: const Text('❤️', style: TextStyle(fontSize: 24)),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class _HeartData {
  final double x;
  final AnimationController controller;

  _HeartData({required this.x, required this.controller});
}

/// Animated typing indicator
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final delay = index * 0.2;
              final animValue = ((_controller.value + delay) % 1.0);
              final scale = 0.5 + (animValue < 0.5 ? animValue : 1 - animValue);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(
                        alpha: 0.6 + scale * 0.4,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
