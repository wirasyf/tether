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
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _secondaryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
    
    _secondaryController.repeat(reverse: true);
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
        }
      },
    );
  }
  
  Widget _buildLoveExplosion(Offset position) {
    return Stack(
      children: [
        // Expanding ring
        CustomPaint(
          size: widget.screenSize,
          painter: _LoveExplosionPainter(
            center: position,
            progress: _controller.value,
          ),
        ),
        // Central heart
        Positioned(
          left: position.dx - 40,
          top: position.dy - 40 - (_controller.value * 50),
          child: Opacity(
            opacity: 1.0 - _controller.value,
            child: Transform.scale(
              scale: 1.0 + _controller.value * 0.5,
              child: const Text(
                '❤️',
                style: TextStyle(fontSize: 60),
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
        // Rising hand
        Positioned(
          left: position.dx - 40,
          top: position.dy - (_controller.value * 150) - 40,
          child: Opacity(
            opacity: 1.0 - _controller.value,
            child: Transform.scale(
              scale: 1.0 + _controller.value,
              child: const Text(
                '🖐️',
                style: TextStyle(fontSize: 70),
              ),
            ),
          ),
        ),
        // Impact waves
        CustomPaint(
          size: widget.screenSize,
          painter: _HighFiveWavePainter(
            center: position,
            progress: _controller.value,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCalmingSpiral(Offset position) {
    return CustomPaint(
      size: widget.screenSize,
      painter: _CalmingSpiralPainter(
        center: position,
        progress: _controller.value,
        secondaryProgress: _secondaryController.value,
      ),
    );
  }
  
  Widget _buildPinchEffect(Offset position) {
    return Stack(
      children: [
        // Pinching fingers
        Positioned(
          left: position.dx - 30 + (_controller.value * 20),
          top: position.dy - 25,
          child: Opacity(
            opacity: 1.0 - _controller.value,
            child: const Text('👆', style: TextStyle(fontSize: 40)),
          ),
        ),
        Positioned(
          left: position.dx - 10 - (_controller.value * 20),
          top: position.dy - 25,
          child: Opacity(
            opacity: 1.0 - _controller.value,
            child: const Text('👆', style: TextStyle(fontSize: 40)),
          ),
        ),
        // Impact burst
        CustomPaint(
          size: widget.screenSize,
          painter: _PinchBurstPainter(
            center: position,
            progress: _controller.value,
          ),
        ),
      ],
    );
  }
}

class _LoveExplosionPainter extends CustomPainter {
  final Offset center;
  final double progress;
  
  _LoveExplosionPainter({required this.center, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    
    // Draw expanding hearts
    for (int i = 0; i < 15; i++) {
      final angle = (i / 15) * 2 * math.pi;
      final distance = 50 + progress * 200 * (0.5 + random.nextDouble() * 0.5);
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance - progress * 30;
      
      final opacity = (1.0 - progress) * (0.5 + random.nextDouble() * 0.5);
      final heartSize = 10 + random.nextDouble() * 15;
      
      _drawHeart(canvas, Offset(x, y), heartSize, opacity);
    }
    
    // Draw expanding ring
    final ringPaint = Paint()
      ..color = Color.fromRGBO(AppColors.loveRed.red, AppColors.loveRed.green, AppColors.loveRed.blue, (1.0 - progress) * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawCircle(center, progress * 150, ringPaint);
  }
  
  void _drawHeart(Canvas canvas, Offset center, double size, double opacity) {
    final paint = Paint()
      ..color = Color.fromRGBO(AppColors.loveRed.red, AppColors.loveRed.green, AppColors.loveRed.blue, opacity)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx - size, center.dy - size * 0.2,
      center.dx - size * 0.5, center.dy - size,
      center.dx, center.dy - size * 0.5,
    );
    path.cubicTo(
      center.dx + size * 0.5, center.dy - size,
      center.dx + size, center.dy - size * 0.2,
      center.dx, center.dy + size * 0.3,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LoveExplosionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _HighFiveWavePainter extends CustomPainter {
  final Offset center;
  final double progress;
  
  _HighFiveWavePainter({required this.center, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Multiple expanding waves
    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress - i * 0.15).clamp(0.0, 1.0);
      if (waveProgress <= 0) continue;
      
      final paint = Paint()
        ..color = Color.fromRGBO(AppColors.highFiveGold.red, AppColors.highFiveGold.green, AppColors.highFiveGold.blue, (1.0 - waveProgress) * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 - waveProgress * 4;
      
      canvas.drawCircle(center, waveProgress * 180, paint);
    }
    
    // Sparkle lines
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final startDistance = 30 + progress * 50;
      final endDistance = 60 + progress * 120;
      
      final paint = Paint()
        ..color = Color.fromRGBO(AppColors.highFiveGold.red, AppColors.highFiveGold.green, AppColors.highFiveGold.blue, (1.0 - progress) * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * startDistance,
          center.dy + math.sin(angle) * startDistance,
        ),
        Offset(
          center.dx + math.cos(angle) * endDistance,
          center.dy + math.sin(angle) * endDistance,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HighFiveWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
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
    // Draw calming spiral
    final path = Path();
    const points = 100;
    
    for (int i = 0; i <= points; i++) {
      final t = i / points;
      final visibleT = t * progress;
      final angle = visibleT * 4 * math.pi;
      final radius = 20 + visibleT * 100;
      
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    final paint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          AppColors.calmBlue.withValues(alpha: 0.8),
          AppColors.primary.withValues(alpha: 0.6),
          Colors.cyan.withValues(alpha: 0.8),
          AppColors.calmBlue.withValues(alpha: 0.8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 150))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(path, paint);
    
    // Floating orbs
    for (int i = 0; i < 6; i++) {
      final orbitAngle = (i / 6) * 2 * math.pi + progress * 2 * math.pi;
      final orbitRadius = 60 + secondaryProgress * 20;
      
      final x = center.dx + math.cos(orbitAngle) * orbitRadius;
      final y = center.dy + math.sin(orbitAngle) * orbitRadius;
      
      final orbPaint = Paint()
        ..color = Color.fromRGBO(AppColors.calmBlue.red, AppColors.calmBlue.green, AppColors.calmBlue.blue, (1.0 - progress) * 0.7)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      
      canvas.drawCircle(Offset(x, y), 8, orbPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CalmingSpiralPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.secondaryProgress != secondaryProgress;
  }
}

class _PinchBurstPainter extends CustomPainter {
  final Offset center;
  final double progress;
  
  _PinchBurstPainter({required this.center, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Quick sharp burst
    final burstProgress = progress < 0.3 ? progress / 0.3 : 1.0 - (progress - 0.3) / 0.7;
    
    // Central flash
    final flashPaint = Paint()
      ..color = Color.fromRGBO(AppColors.pinchOrange.red, AppColors.pinchOrange.green, AppColors.pinchOrange.blue, burstProgress * 0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 20 + burstProgress * 30, flashPaint);
    
    // Sharp rays
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      final length = 20 + progress * 80;
      
      final paint = Paint()
        ..color = Color.fromRGBO(AppColors.pinchOrange.red, AppColors.pinchOrange.green, AppColors.pinchOrange.blue, (1.0 - progress) * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * 10,
          center.dy + math.sin(angle) * 10,
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
  bool shouldRepaint(covariant _PinchBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
