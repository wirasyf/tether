import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../core/services/theme_service.dart';

/// Premium animated gradient background with floating particles and mesh movement
class AnimatedBackground extends StatefulWidget {
  final Widget? child;
  final List<Color>? colors;
  final bool enableParticles;

  const AnimatedBackground({
    super.key,
    this.child,
    this.colors,
    this.enableParticles = true,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late List<_Particle> _particles;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Generate particles
    _particles = List.generate(30, (index) => _Particle.random(_random));
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _controller,
        _pulseController,
        _particleController,
        ThemeService.instance,
      ]),
      builder: (context, child) {
        final theme = ThemeService.instance;
        final primaryColor = Color(theme.primaryColor);
        final secondaryColor = Color(theme.secondaryColor);
        final bgColor = Color(theme.backgroundColor);

        return CustomPaint(
          painter: _BackgroundPainter(
            animationValue: _controller.value,
            pulseValue: _pulseController.value,
            particleValue: _particleController.value,
            particles: (widget.enableParticles && theme.showParticles)
                ? _particles
                : [],
            colors:
                widget.colors ??
                [
                  bgColor,
                  bgColor.withValues(alpha: 0.9),
                  primaryColor.withValues(alpha: 0.25),
                  secondaryColor.withValues(alpha: 0.15),
                ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double offset;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.offset,
  });

  factory _Particle.random(math.Random random) {
    return _Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: 1 + random.nextDouble() * 3,
      speed: 0.2 + random.nextDouble() * 0.8,
      opacity: 0.2 + random.nextDouble() * 0.6,
      offset: random.nextDouble() * 2 * math.pi,
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double animationValue;
  final double pulseValue;
  final double particleValue;
  final List<_Particle> particles;
  final List<Color> colors;

  _BackgroundPainter({
    required this.animationValue,
    required this.pulseValue,
    required this.particleValue,
    required this.particles,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Deep space gradient background
    final baseGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [colors[0], Color.lerp(colors[0], colors[1], 0.3)!, colors[1]],
      stops: const [0.0, 0.5, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = baseGradient.createShader(rect));

    // Animated nebula orbs
    final orbPaint = Paint()..blendMode = BlendMode.plus;

    // First orb (top right - primary color)
    final orb1Center = Offset(
      size.width * (0.85 + 0.08 * math.sin(animationValue * 2 * math.pi)),
      size.height * (0.15 + 0.08 * math.cos(animationValue * 2 * math.pi)),
    );
    final orb1Radius = size.width * 0.45 * (0.85 + 0.15 * pulseValue);
    orbPaint.shader = RadialGradient(
      colors: [
        colors[2].withValues(alpha: 0.35),
        colors[2].withValues(alpha: 0.15),
        colors[2].withValues(alpha: 0.05),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.6, 1.0],
    ).createShader(Rect.fromCircle(center: orb1Center, radius: orb1Radius));
    canvas.drawCircle(orb1Center, orb1Radius, orbPaint);

    // Second orb (bottom left - secondary color)
    final orb2Center = Offset(
      size.width * (0.15 + 0.12 * math.cos(animationValue * 2 * math.pi + 1)),
      size.height * (0.75 + 0.08 * math.sin(animationValue * 2 * math.pi + 1)),
    );
    final orb2Radius = size.width * 0.55 * (0.9 + 0.1 * pulseValue);
    orbPaint.shader = RadialGradient(
      colors: [
        colors[3].withValues(alpha: 0.25),
        colors[3].withValues(alpha: 0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: orb2Center, radius: orb2Radius));
    canvas.drawCircle(orb2Center, orb2Radius, orbPaint);

    // Third orb (center - subtle pulsing)
    final orb3Center = Offset(
      size.width * 0.5,
      size.height * (0.45 + 0.03 * math.sin(animationValue * 4 * math.pi)),
    );
    final orb3Radius = size.width * 0.35 * (0.7 + 0.3 * pulseValue);
    orbPaint.shader = RadialGradient(
      colors: [
        AppColors.primary.withValues(alpha: 0.08 + 0.04 * pulseValue),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: orb3Center, radius: orb3Radius));
    canvas.drawCircle(orb3Center, orb3Radius, orbPaint);

    // Draw floating particles/stars
    if (particles.isNotEmpty) {
      final particlePaint = Paint()..style = PaintingStyle.fill;

      for (final particle in particles) {
        final particleProgress =
            (particleValue * particle.speed + particle.offset) % 1.0;

        // Floating motion
        final px =
            particle.x * size.width +
            math.sin(particleProgress * 2 * math.pi) * 15;
        final py =
            particle.y * size.height +
            math.cos(particleProgress * 2 * math.pi + particle.offset) * 20;

        // Twinkle effect
        final twinkle = 0.5 + 0.5 * math.sin(particleProgress * 4 * math.pi);
        final opacity = particle.opacity * twinkle;

        particlePaint.color = Colors.white.withValues(alpha: opacity);

        // Draw glow
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(px, py), particle.size * 1.5, glowPaint);

        // Draw particle core
        canvas.drawCircle(Offset(px, py), particle.size * 0.5, particlePaint);
      }
    }

    // Subtle vignette effect
    final vignettePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.transparent,
              Colors.transparent,
              colors[0].withValues(alpha: 0.5),
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: size.width * 0.9,
            ),
          );
    canvas.drawRect(rect, vignettePaint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.particleValue != particleValue;
  }
}
