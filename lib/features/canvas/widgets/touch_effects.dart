import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../core/services/theme_service.dart';
import '../../../models/gesture_type.dart';

/// Ripple effect animation widget
class RippleEffect extends StatefulWidget {
  final Offset position;
  final Color? color;
  final double maxRadius;
  final VoidCallback? onComplete;
  final bool isFromPartner;

  const RippleEffect({
    super.key,
    required this.position,
    this.color,
    this.maxRadius = 100,
    this.onComplete,
    this.isFromPartner = false,
  });

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radiusAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _radiusAnimation = Tween<double>(
      begin: 0,
      end: widget.maxRadius,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    // Use custom touch color from ThemeService
    final touchColor = Color(ThemeService.instance.touchColorValue);
    final baseColor =
        widget.color ??
        (widget.isFromPartner ? AppColors.secondary : touchColor);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _RipplePainter(
            center: widget.position,
            radius: _radiusAnimation.value,
            opacity: _opacityAnimation.value,
            color: baseColor,
          ),
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double opacity;
  final Color color;

  _RipplePainter({
    required this.center,
    required this.radius,
    required this.opacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromRGBO(color.red, color.green, color.blue, opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, paint);

    // Inner glow
    final glowPaint = Paint()
      ..color = Color.fromRGBO(
        color.red,
        color.green,
        color.blue,
        opacity * 0.3,
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.8, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.opacity != opacity;
  }
}

/// Glow trail effect for touch movement
class GlowTrailEffect extends StatefulWidget {
  final List<Offset> points;
  final Color? color;
  final bool isFromPartner;

  const GlowTrailEffect({
    super.key,
    required this.points,
    this.color,
    this.isFromPartner = false,
  });

  @override
  State<GlowTrailEffect> createState() => _GlowTrailEffectState();
}

class _GlowTrailEffectState extends State<GlowTrailEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final touchColor = Color(ThemeService.instance.touchColorValue);
    final baseColor =
        widget.color ??
        (widget.isFromPartner ? AppColors.secondary : touchColor);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GlowTrailPainter(points: widget.points, color: baseColor),
        );
      },
    );
  }
}

class _GlowTrailPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  _GlowTrailPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    for (int i = 0; i < points.length; i++) {
      final opacity = (i + 1) / points.length;
      final radius = 8.0 * opacity + 4;

      final paint = Paint()
        ..color = Color.fromRGBO(
          color.red,
          color.green,
          color.blue,
          opacity * 0.6,
        )
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(points[i], radius, paint);
    }

    // Draw connecting line
    if (points.length >= 2) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      final linePaint = Paint()
        ..color = Color.fromRGBO(color.red, color.green, color.blue, 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowTrailPainter oldDelegate) {
    return oldDelegate.points.length != points.length;
  }
}

/// Particle burst effect for gestures
class ParticleBurstEffect extends StatefulWidget {
  final Offset position;
  final GestureType gestureType;
  final VoidCallback? onComplete;

  const ParticleBurstEffect({
    super.key,
    required this.position,
    required this.gestureType,
    this.onComplete,
  });

  @override
  State<ParticleBurstEffect> createState() => _ParticleBurstEffectState();
}

class _ParticleBurstEffectState extends State<ParticleBurstEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _particles = _generateParticles();

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  List<_Particle> _generateParticles() {
    final random = math.Random();
    final count = widget.gestureType == GestureType.doubleTap ? 20 : 12;

    return List.generate(count, (index) {
      final angle = (index / count) * 2 * math.pi;
      final speed = 100 + random.nextDouble() * 150;

      return _Particle(
        angle: angle + random.nextDouble() * 0.3,
        speed: speed,
        size: 4 + random.nextDouble() * 8,
        color: _getParticleColor(random),
      );
    });
  }

  Color _getParticleColor(math.Random random) {
    switch (widget.gestureType) {
      case GestureType.doubleTap:
        return [AppColors.loveRed, Colors.pink, Colors.pinkAccent][random
            .nextInt(3)];
      case GestureType.swipeUp:
        return [AppColors.highFiveGold, Colors.amber, Colors.orange][random
            .nextInt(3)];
      case GestureType.circleMotion:
        return [AppColors.calmBlue, Colors.lightBlue, Colors.cyan][random
            .nextInt(3)];
      case GestureType.pinch:
        return [AppColors.pinchOrange, Colors.deepOrange, Colors.amber][random
            .nextInt(3)];
      case GestureType.hug:
        return [Colors.purple, Colors.deepPurple, Colors.purpleAccent][random
            .nextInt(3)];
      case GestureType.kiss:
        return [Colors.pink, Colors.pinkAccent, Colors.red][random.nextInt(3)];
      case GestureType.heartbeat:
        return [Colors.red, Colors.redAccent, Colors.pink][random.nextInt(3)];
      case GestureType.thinkingOfYou:
        return [Colors.purple, Colors.indigo, Colors.deepPurple][random.nextInt(
          3,
        )];
      case GestureType.goodnight:
        return [Colors.indigo, Colors.blueGrey, Colors.blue][random.nextInt(3)];
    }
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
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticleBurstPainter(
            center: widget.position,
            particles: _particles,
            progress: _controller.value,
            gestureType: widget.gestureType,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _ParticleBurstPainter extends CustomPainter {
  final Offset center;
  final List<_Particle> particles;
  final double progress;
  final GestureType gestureType;

  _ParticleBurstPainter({
    required this.center,
    required this.particles,
    required this.progress,
    required this.gestureType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw central symbol first
    _drawCentralSymbol(canvas);

    // Draw particles
    for (var particle in particles) {
      final distance = particle.speed * progress;
      final x = center.dx + math.cos(particle.angle) * distance;
      final y =
          center.dy + math.sin(particle.angle) * distance - (progress * 50);

      final opacity = 1.0 - progress;
      final currentSize = particle.size * (1.0 - progress * 0.5);

      final paint = Paint()
        ..color = Color.fromRGBO(
          particle.color.red,
          particle.color.green,
          particle.color.blue,
          opacity,
        )
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      if (gestureType == GestureType.doubleTap) {
        _drawHeart(canvas, Offset(x, y), currentSize, paint);
      } else {
        canvas.drawCircle(Offset(x, y), currentSize, paint);
      }
    }
  }

  void _drawCentralSymbol(Canvas canvas) {
    final opacity = 1.0 - progress;
    final scale = 1.0 + progress * 0.5;

    switch (gestureType) {
      case GestureType.doubleTap:
        _drawLargeHeart(canvas, center, 30 * scale, opacity);
        break;
      case GestureType.swipeUp:
        _drawHighFive(canvas, center, 35 * scale, opacity);
        break;
      case GestureType.circleMotion:
        _drawSparkle(canvas, center, 25 * scale, opacity);
        break;
      case GestureType.pinch:
        _drawPinch(canvas, center, 20 * scale, opacity);
        break;
      case GestureType.hug:
      case GestureType.kiss:
      case GestureType.heartbeat:
      case GestureType.thinkingOfYou:
      case GestureType.goodnight:
        // These gestures are handled by GestureEffects with emoji
        break;
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx - size,
      center.dy - size * 0.2,
      center.dx - size * 0.5,
      center.dy - size,
      center.dx,
      center.dy - size * 0.5,
    );
    path.cubicTo(
      center.dx + size * 0.5,
      center.dy - size,
      center.dx + size,
      center.dy - size * 0.2,
      center.dx,
      center.dy + size * 0.3,
    );
    canvas.drawPath(path, paint);
  }

  void _drawLargeHeart(
    Canvas canvas,
    Offset center,
    double size,
    double opacity,
  ) {
    final paint = Paint()
      ..color = Color.fromRGBO(
        AppColors.loveRed.red,
        AppColors.loveRed.green,
        AppColors.loveRed.blue,
        opacity,
      )
      ..style = PaintingStyle.fill;
    _drawHeart(canvas, center, size, paint);
  }

  void _drawHighFive(
    Canvas canvas,
    Offset center,
    double size,
    double opacity,
  ) {
    final paint = Paint()
      ..color = Color.fromRGBO(
        AppColors.highFiveGold.red,
        AppColors.highFiveGold.green,
        AppColors.highFiveGold.blue,
        opacity,
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + (i - 2) * 0.25;
      final x = center.dx + math.cos(angle) * size * 0.6;
      final y = center.dy + math.sin(angle) * size * 0.8;
      canvas.drawCircle(Offset(x, y), size * 0.15, paint);
    }
    canvas.drawCircle(center, size * 0.35, paint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, double opacity) {
    final paint = Paint()
      ..color = Color.fromRGBO(
        AppColors.calmBlue.red,
        AppColors.calmBlue.green,
        AppColors.calmBlue.blue,
        opacity,
      )
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi - math.pi / 2;
      final radius = i.isEven ? size : size * 0.4;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawPinch(Canvas canvas, Offset center, double size, double opacity) {
    final paint = Paint()
      ..color = Color.fromRGBO(
        AppColors.pinchOrange.red,
        AppColors.pinchOrange.green,
        AppColors.pinchOrange.blue,
        opacity,
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(center.dx - size * 0.4, center.dy),
      size * 0.3,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + size * 0.4, center.dy),
      size * 0.3,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ParticleBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Touch point indicator (current touch position)
class TouchPointIndicator extends StatefulWidget {
  final Offset position;
  final bool isActive;
  final bool isFromPartner;

  const TouchPointIndicator({
    super.key,
    required this.position,
    required this.isActive,
    this.isFromPartner = false,
  });

  @override
  State<TouchPointIndicator> createState() => _TouchPointIndicatorState();
}

class _TouchPointIndicatorState extends State<TouchPointIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    final touchColor = Color(ThemeService.instance.touchColorValue);
    final baseColor = widget.isFromPartner ? AppColors.secondary : touchColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = 0.8 + 0.2 * _controller.value;

        return Positioned(
          left: widget.position.dx - 25 * pulse,
          top: widget.position.dy - 25 * pulse,
          child: Container(
            width: 50 * pulse,
            height: 50 * pulse,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  baseColor.withValues(alpha: 0.6),
                  baseColor.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
