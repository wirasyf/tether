import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';

/// Animated gradient background with subtle mesh movement
class AnimatedBackground extends StatefulWidget {
  final Widget? child;
  final List<Color>? colors;
  
  const AnimatedBackground({
    super.key,
    this.child,
    this.colors,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _pulseController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _BackgroundPainter(
            animationValue: _controller.value,
            pulseValue: _pulseController.value,
            colors: widget.colors ?? [
              AppColors.background,
              AppColors.backgroundLight,
              AppColors.primaryDark.withValues(alpha: 0.3),
              AppColors.secondaryDark.withValues(alpha: 0.2),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double animationValue;
  final double pulseValue;
  final List<Color> colors;
  
  _BackgroundPainter({
    required this.animationValue,
    required this.pulseValue,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // Base gradient
    final baseGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colors[0], colors[1]],
    );
    canvas.drawRect(rect, Paint()..shader = baseGradient.createShader(rect));
    
    // Animated orbs
    final orbPaint = Paint()..blendMode = BlendMode.plus;
    
    // First orb (top right)
    final orb1Center = Offset(
      size.width * (0.8 + 0.1 * math.sin(animationValue * 2 * math.pi)),
      size.height * (0.2 + 0.1 * math.cos(animationValue * 2 * math.pi)),
    );
    final orb1Radius = size.width * 0.4 * (0.8 + 0.2 * pulseValue);
    orbPaint.shader = RadialGradient(
      colors: [
        colors[2].withValues(alpha: 0.4),
        colors[2].withValues(alpha: 0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: orb1Center, radius: orb1Radius));
    canvas.drawCircle(orb1Center, orb1Radius, orbPaint);
    
    // Second orb (bottom left)
    final orb2Center = Offset(
      size.width * (0.2 + 0.15 * math.cos(animationValue * 2 * math.pi + 1)),
      size.height * (0.7 + 0.1 * math.sin(animationValue * 2 * math.pi + 1)),
    );
    final orb2Radius = size.width * 0.5 * (0.9 + 0.1 * pulseValue);
    orbPaint.shader = RadialGradient(
      colors: [
        colors[3].withValues(alpha: 0.3),
        colors[3].withValues(alpha: 0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: orb2Center, radius: orb2Radius));
    canvas.drawCircle(orb2Center, orb2Radius, orbPaint);
    
    // Third subtle orb (center)
    final orb3Center = Offset(
      size.width * 0.5,
      size.height * (0.5 + 0.05 * math.sin(animationValue * 4 * math.pi)),
    );
    final orb3Radius = size.width * 0.3 * pulseValue;
    orbPaint.shader = RadialGradient(
      colors: [
        AppColors.primary.withValues(alpha: 0.1),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: orb3Center, radius: orb3Radius));
    canvas.drawCircle(orb3Center, orb3Radius, orbPaint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.pulseValue != pulseValue;
  }
}
