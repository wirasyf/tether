import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/gesture_type.dart';
import '../../core/theme/app_colors.dart';

/// Special effects for different gesture types
class GestureEffects extends StatefulWidget {
  final GestureEvent gesture;
  final Size screenSize;
  final VoidCallback? onComplete;

  const GestureEffects({
    super.key,
    required this.gesture,
    required this.screenSize,
    this.onComplete,
  });

  @override
  State<GestureEffects> createState() => _GestureEffectsState();
}

class _GestureEffectsState extends State<GestureEffects>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _secondaryController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _getDuration(), vsync: this);

    _secondaryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });

    _secondaryController.repeat(reverse: true);
  }

  Duration _getDuration() {
    switch (widget.gesture.type) {
      case GestureType.heartbeat:
        return const Duration(milliseconds: 2500);
      case GestureType.hug:
        return const Duration(milliseconds: 2000);
      case GestureType.goodnight:
        return const Duration(milliseconds: 3000);
      default:
        return const Duration(milliseconds: 1500);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = Offset(
      widget.gesture.x * widget.screenSize.width,
      widget.gesture.y * widget.screenSize.height,
    );

    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _secondaryController]),
      builder: (context, child) {
        switch (widget.gesture.type) {
          case GestureType.doubleTap:
            return _buildLoveExplosion(position);
          case GestureType.swipeUp:
            return _buildHighFiveEffect(position);
          case GestureType.circleMotion:
            return _buildCalmingSpiral(position);
          case GestureType.pinch:
            return _buildPinchEffect(position);
          case GestureType.hug:
            return _buildHugEffect(position);
          case GestureType.kiss:
            return _buildKissEffect(position);
          case GestureType.heartbeat:
            return _buildHeartbeatEffect(position);
          case GestureType.thinkingOfYou:
            return _buildThinkingOfYouEffect(position);
          case GestureType.goodnight:
            return _buildGoodnightEffect(position);
        }
      },
    );
  }

  Widget _buildLoveExplosion(Offset position) {
    return Stack(
      children: [
        CustomPaint(
          size: widget.screenSize,
          painter: _LoveExplosionPainter(
            center: position,
            progress: _controller.value,
          ),
        ),
        Positioned(
          left: position.dx - 100,
          top: position.dy - 100,
          child: SizedBox(
            width: 200,
            height: 200,
            child: Opacity(
              opacity: 1.0 - _controller.value,
              child: Transform.scale(
                scale: 1.0 + _controller.value * 0.5,
                child: const Text('❤️', style: TextStyle(fontSize: 60)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighFiveEffect(Offset position) {
    return Stack(
      children: [
        CustomPaint(
          size: widget.screenSize,
          painter: _HighFiveWavePainter(
            center: position,
            progress: _controller.value,
          ),
        ),
        Positioned(
          left: position.dx - 50,
          top: position.dy - 100 - (_controller.value * 80),
          child: Opacity(
            opacity: 1.0 - _controller.value,
            child: Transform.scale(
              scale: 1.0 + _controller.value,
              child: const Text('🖐️', style: TextStyle(fontSize: 70)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalmingSpiral(Offset position) {
    return Stack(
      children: [
        CustomPaint(
          size: widget.screenSize,
          painter: _CalmingSpiralPainter(
            center: position,
            progress: _controller.value,
            secondaryProgress: _secondaryController.value,
          ),
        ),
        Positioned(
          left: position.dx - 40,
          top: position.dy - 40,
          child: Opacity(
            opacity: 0.8 - _controller.value * 0.3,
            child: Transform.rotate(
              angle: _controller.value * math.pi * 2,
              child: const Text('✨', style: TextStyle(fontSize: 60)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinchEffect(Offset position) {
    return Stack(
      children: [
        CustomPaint(
          size: widget.screenSize,
          painter: _PinchBurstPainter(
            center: position,
            progress: _controller.value,
          ),
        ),
        Positioned(
          left: position.dx - 30 + (_controller.value * 30),
          top: position.dy - 30,
          child: Opacity(
            opacity: 1.0 - _controller.value,
            child: const Text('👆', style: TextStyle(fontSize: 40)),
          ),
        ),
        Positioned(
          left: position.dx - 10 - (_controller.value * 30),
          top: position.dy - 30,
          child: Opacity(
            opacity: 1.0 - _controller.value,
            child: const Text('👆', style: TextStyle(fontSize: 40)),
          ),
        ),
      ],
    );
  }

  // NEW GESTURE EFFECTS

  Widget _buildHugEffect(Offset position) {
    return Stack(
      children: [
        // Warm glow background
        CustomPaint(
          size: widget.screenSize,
          painter: _HugGlowPainter(
            center: position,
            progress: _controller.value,
            pulseProgress: _secondaryController.value,
          ),
        ),
        // Hugging emoji with pulse
        Positioned(
          left: position.dx - 60,
          top: position.dy - 60,
          child: Transform.scale(
            scale: 1.0 + (_secondaryController.value * 0.15),
            child: Opacity(
              opacity: 1.0 - (_controller.value * 0.3),
              child: const Text('🫂', style: TextStyle(fontSize: 100)),
            ),
          ),
        ),
        // Floating hearts around
        for (int i = 0; i < 6; i++) _buildFloatingHeart(position, i),
      ],
    );
  }

  Widget _buildFloatingHeart(Offset center, int index) {
    final angle = (index / 6) * 2 * math.pi + _controller.value * math.pi;
    final radius = 80 + _controller.value * 60;
    final x = center.dx + math.cos(angle) * radius - 15;
    final y =
        center.dy + math.sin(angle) * radius - 15 - (_controller.value * 40);

    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: (1.0 - _controller.value) * 0.8,
        child: Transform.scale(
          scale: 0.5 + _controller.value * 0.3,
          child: Text(
            index % 2 == 0 ? '💕' : '💖',
            style: const TextStyle(fontSize: 30),
          ),
        ),
      ),
    );
  }

  Widget _buildKissEffect(Offset position) {
    return Stack(
      children: [
        // Kiss mark burst
        CustomPaint(
          size: widget.screenSize,
          painter: _KissBurstPainter(
            center: position,
            progress: _controller.value,
          ),
        ),
        // Main kiss emoji rising
        Positioned(
          left: position.dx - 40,
          top: position.dy - 40 - (_controller.value * 100),
          child: Opacity(
            opacity: 1.0 - _controller.value,
            child: Transform.scale(
              scale: 1.2 + _controller.value * 0.5,
              child: const Text('💋', style: TextStyle(fontSize: 70)),
            ),
          ),
        ),
        // Lip marks flying out
        for (int i = 0; i < 5; i++) _buildFlyingKiss(position, i),
      ],
    );
  }

  Widget _buildFlyingKiss(Offset center, int index) {
    final angle = (index / 5) * math.pi - math.pi / 2;
    final distance = 50 + _controller.value * 120;
    final x = center.dx + math.cos(angle) * distance - 20;
    final y =
        center.dy + math.sin(angle) * distance - 20 - (_controller.value * 50);

    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: (1.0 - _controller.value) * 0.9,
        child: Transform.rotate(
          angle: angle,
          child: const Text('💗', style: TextStyle(fontSize: 30)),
        ),
      ),
    );
  }

  Widget _buildHeartbeatEffect(Offset position) {
    // Pulsing heart effect
    final pulsePhase = (_controller.value * 4) % 1.0;
    final pulse = pulsePhase < 0.3
        ? pulsePhase / 0.3
        : (pulsePhase < 0.5 ? 1.0 - (pulsePhase - 0.3) / 0.2 : 0.0);

    return Stack(
      children: [
        // Heartbeat wave rings
        CustomPaint(
          size: widget.screenSize,
          painter: _HeartbeatPainter(
            center: position,
            progress: _controller.value,
          ),
        ),
        // Pulsing heart
        Positioned(
          left: position.dx - 50,
          top: position.dy - 50,
          child: Transform.scale(
            scale: 1.0 + pulse * 0.3,
            child: Opacity(
              opacity: 1.0 - (_controller.value * 0.3),
              child: const Text('💓', style: TextStyle(fontSize: 80)),
            ),
          ),
        ),
        // ECG-like wave text
        Positioned(
          left: position.dx - 100,
          top: position.dy + 60,
          child: Opacity(
            opacity: 1.0 - _controller.value,
            child: Text(
              '~ ♥ ~',
              style: TextStyle(
                fontSize: 24,
                color: Colors.pink.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThinkingOfYouEffect(Offset position) {
    return Stack(
      children: [
        // Dreamy floating bubbles
        CustomPaint(
          size: widget.screenSize,
          painter: _ThinkingBubblesPainter(
            center: position,
            progress: _controller.value,
          ),
        ),
        // Main thought bubble
        Positioned(
          left: position.dx - 40,
          top: position.dy - 40 - (_controller.value * 80),
          child: Opacity(
            opacity: 1.0 - (_controller.value * 0.5),
            child: Transform.scale(
              scale: 1.0 + _controller.value * 0.2,
              child: const Text('💭', style: TextStyle(fontSize: 70)),
            ),
          ),
        ),
        // Heart inside thought
        Positioned(
          left: position.dx - 15,
          top: position.dy - 30 - (_controller.value * 80),
          child: Opacity(
            opacity: (1.0 - _controller.value) * 0.9,
            child: Transform.scale(
              scale: 0.8 + _secondaryController.value * 0.2,
              child: const Text('❤️', style: TextStyle(fontSize: 25)),
            ),
          ),
        ),
        // Sparkles around
        for (int i = 0; i < 4; i++) _buildSparkle(position, i),
      ],
    );
  }

  Widget _buildSparkle(Offset center, int index) {
    final angle = (index / 4) * 2 * math.pi + _controller.value * math.pi;
    final radius = 60 + _secondaryController.value * 20;
    final x = center.dx + math.cos(angle) * radius - 15;
    final y = center.dy + math.sin(angle) * radius - 15;

    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: 0.6 + _secondaryController.value * 0.4,
        child: Text(
          index % 2 == 0 ? '✨' : '💫',
          style: const TextStyle(fontSize: 25),
        ),
      ),
    );
  }

  Widget _buildGoodnightEffect(Offset position) {
    return Stack(
      children: [
        // Starry night background
        CustomPaint(
          size: widget.screenSize,
          painter: _GoodnightPainter(
            center: position,
            progress: _controller.value,
            twinkle: _secondaryController.value,
          ),
        ),
        // Moon
        Positioned(
          left: position.dx - 50,
          top: position.dy - 50 - (_controller.value * 30),
          child: Transform.scale(
            scale: 1.0 + _secondaryController.value * 0.1,
            child: Opacity(
              opacity: 1.0 - (_controller.value * 0.3),
              child: const Text('🌙', style: TextStyle(fontSize: 80)),
            ),
          ),
        ),
        // Stars around
        for (int i = 0; i < 8; i++) _buildStar(position, i),
        // Zzz floating
        Positioned(
          left: position.dx + 40,
          top: position.dy - 60 - (_controller.value * 50),
          child: Opacity(
            opacity: (1.0 - _controller.value) * 0.8,
            child: Text(
              'Z z z',
              style: TextStyle(
                fontSize: 28,
                color: Colors.indigo.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStar(Offset center, int index) {
    final angle = (index / 8) * 2 * math.pi;
    final radius = 80 + (index % 3) * 30;
    final x =
        center.dx +
        math.cos(angle) * radius * (0.8 + _controller.value * 0.3) -
        15;
    final y =
        center.dy +
        math.sin(angle) * radius * (0.8 + _controller.value * 0.3) -
        15;
    final opacity = 0.3 + _secondaryController.value * 0.7 * ((index + 1) / 8);

    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: opacity * (1.0 - _controller.value * 0.5),
        child: Text(
          index % 3 == 0 ? '⭐' : (index % 3 == 1 ? '✨' : '💫'),
          style: TextStyle(fontSize: 20 + (index % 2) * 10.0),
        ),
      ),
    );
  }
}

// CUSTOM PAINTERS

class _LoveExplosionPainter extends CustomPainter {
  final Offset center;
  final double progress;

  _LoveExplosionPainter({required this.center, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      final distance = 50 + progress * 180 * (0.5 + random.nextDouble() * 0.5);
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance - progress * 30;

      final opacity = (1.0 - progress) * (0.5 + random.nextDouble() * 0.5);
      _drawHeart(canvas, Offset(x, y), 10 + random.nextDouble() * 10, opacity);
    }

    final ringPaint = Paint()
      ..color = AppColors.loveRed.withValues(alpha: (1.0 - progress) * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, progress * 150, ringPaint);
  }

  void _drawHeart(Canvas canvas, Offset c, double size, double opacity) {
    final paint = Paint()
      ..color = AppColors.loveRed.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(c.dx, c.dy + size * 0.3)
      ..cubicTo(
        c.dx - size,
        c.dy - size * 0.2,
        c.dx - size * 0.5,
        c.dy - size,
        c.dx,
        c.dy - size * 0.5,
      )
      ..cubicTo(
        c.dx + size * 0.5,
        c.dy - size,
        c.dx + size,
        c.dy - size * 0.2,
        c.dx,
        c.dy + size * 0.3,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LoveExplosionPainter old) =>
      old.progress != progress;
}

class _HighFiveWavePainter extends CustomPainter {
  final Offset center;
  final double progress;

  _HighFiveWavePainter({required this.center, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 3; i++) {
      final wave = (progress - i * 0.15).clamp(0.0, 1.0);
      if (wave <= 0) continue;

      final paint = Paint()
        ..color = AppColors.highFiveGold.withValues(alpha: (1.0 - wave) * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 - wave * 3;
      canvas.drawCircle(center, wave * 160, paint);
    }

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final start = 30 + progress * 40;
      final end = 60 + progress * 100;

      final paint = Paint()
        ..color = AppColors.highFiveGold.withValues(
          alpha: (1.0 - progress) * 0.7,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * start,
          center.dy + math.sin(angle) * start,
        ),
        Offset(
          center.dx + math.cos(angle) * end,
          center.dy + math.sin(angle) * end,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HighFiveWavePainter old) =>
      old.progress != progress;
}

class _CalmingSpiralPainter extends CustomPainter {
  final Offset center;
  final double progress;
  final double secondaryProgress;

  _CalmingSpiralPainter({
    required this.center,
    required this.progress,
    required this.secondaryProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const points = 80;

    for (int i = 0; i <= points; i++) {
      final t = i / points;
      final visibleT = t * progress;
      final angle = visibleT * 4 * math.pi;
      final radius = 15 + visibleT * 80;

      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;

      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }

    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.calmBlue.withValues(alpha: 0.8),
          AppColors.primary.withValues(alpha: 0.6),
          Colors.cyan.withValues(alpha: 0.8),
          AppColors.calmBlue.withValues(alpha: 0.8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 120))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    for (int i = 0; i < 5; i++) {
      final orbitAngle = (i / 5) * 2 * math.pi + progress * 2 * math.pi;
      final orbitRadius = 50 + secondaryProgress * 15;
      final x = center.dx + math.cos(orbitAngle) * orbitRadius;
      final y = center.dy + math.sin(orbitAngle) * orbitRadius;

      final orbPaint = Paint()
        ..color = AppColors.calmBlue.withValues(alpha: (1.0 - progress) * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), 6, orbPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CalmingSpiralPainter old) =>
      old.progress != progress || old.secondaryProgress != secondaryProgress;
}

class _PinchBurstPainter extends CustomPainter {
  final Offset center;
  final double progress;

  _PinchBurstPainter({required this.center, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final burst = progress < 0.3
        ? progress / 0.3
        : 1.0 - (progress - 0.3) / 0.7;

    final flashPaint = Paint()
      ..color = AppColors.pinchOrange.withValues(alpha: burst * 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 15 + burst * 25, flashPaint);

    for (int i = 0; i < 10; i++) {
      final angle = (i / 10) * 2 * math.pi;
      final length = 15 + progress * 70;

      final paint = Paint()
        ..color = AppColors.pinchOrange.withValues(
          alpha: (1.0 - progress) * 0.8,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * 8,
          center.dy + math.sin(angle) * 8,
        ),
        Offset(
          center.dx + math.cos(angle) * length,
          center.dy + math.sin(angle) * length,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PinchBurstPainter old) =>
      old.progress != progress;
}

// NEW PAINTERS

class _HugGlowPainter extends CustomPainter {
  final Offset center;
  final double progress;
  final double pulseProgress;

  _HugGlowPainter({
    required this.center,
    required this.progress,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Warm glow circles
    for (int i = 3; i > 0; i--) {
      final radius = 60 + i * 40 + pulseProgress * 20;
      final paint = Paint()
        ..color = Color(
          0xFFE040FB,
        ).withValues(alpha: (1.0 - progress) * 0.15 / i)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HugGlowPainter old) =>
      old.progress != progress || old.pulseProgress != pulseProgress;
}

class _KissBurstPainter extends CustomPainter {
  final Offset center;
  final double progress;

  _KissBurstPainter({required this.center, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Pink burst rings
    for (int i = 0; i < 2; i++) {
      final wave = (progress - i * 0.2).clamp(0.0, 1.0);
      if (wave <= 0) continue;

      final paint = Paint()
        ..color = const Color(0xFFFF69B4).withValues(alpha: (1.0 - wave) * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 - wave * 2;
      canvas.drawCircle(center, wave * 120, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _KissBurstPainter old) =>
      old.progress != progress;
}

class _HeartbeatPainter extends CustomPainter {
  final Offset center;
  final double progress;

  _HeartbeatPainter({required this.center, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Multiple heartbeat waves
    for (int i = 0; i < 4; i++) {
      final wave = ((progress * 4) - i * 0.8) % 1.0;
      if (wave < 0 || wave > 1) continue;

      final paint = Paint()
        ..color = const Color(0xFFFF4081).withValues(alpha: (1.0 - wave) * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 - wave * 2;
      canvas.drawCircle(center, 40 + wave * 100, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeartbeatPainter old) =>
      old.progress != progress;
}

class _ThinkingBubblesPainter extends CustomPainter {
  final Offset center;
  final double progress;

  _ThinkingBubblesPainter({required this.center, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(99);

    // Floating thought bubbles
    for (int i = 0; i < 8; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final baseRadius = 30 + random.nextDouble() * 60;
      final radius = baseRadius + progress * 40;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius - progress * 50;
      final bubbleSize = 5 + random.nextDouble() * 10;

      final paint = Paint()
        ..color = const Color(
          0xFF9C27B0,
        ).withValues(alpha: (1.0 - progress) * 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), bubbleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ThinkingBubblesPainter old) =>
      old.progress != progress;
}

class _GoodnightPainter extends CustomPainter {
  final Offset center;
  final double progress;
  final double twinkle;

  _GoodnightPainter({
    required this.center,
    required this.progress,
    required this.twinkle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Night sky gradient effect
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3F51B5).withValues(alpha: (1.0 - progress) * 0.3),
          const Color(0xFF1A237E).withValues(alpha: (1.0 - progress) * 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 150));
    canvas.drawCircle(center, 150, gradientPaint);

    // Twinkling stars
    final random = math.Random(77);
    for (int i = 0; i < 15; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final dist = 40 + random.nextDouble() * 120;
      final x = center.dx + math.cos(angle) * dist;
      final y = center.dy + math.sin(angle) * dist;
      final starSize = 1 + random.nextDouble() * 2;
      final opacity =
          (0.3 + twinkle * 0.7 * random.nextDouble()) * (1.0 - progress * 0.5);

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
      canvas.drawCircle(Offset(x, y), starSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GoodnightPainter old) =>
      old.progress != progress || old.twinkle != twinkle;
}
