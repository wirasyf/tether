import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/storage_service.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/connection_status.dart';
import '../../shared/widgets/glass_card.dart';
import 'canvas_controller.dart';
import 'widgets/touch_effects.dart';
import '../gestures/gesture_effects.dart';

/// Main touch canvas screen - the virtual canvas for touch communication
class TouchCanvasScreen extends StatefulWidget {
  const TouchCanvasScreen({super.key});

  @override
  State<TouchCanvasScreen> createState() => _TouchCanvasScreenState();
}

class _TouchCanvasScreenState extends State<TouchCanvasScreen> {
  late CanvasController _controller;
  bool _showInstructions = true;
  
  @override
  void initState() {
    super.initState();
    _controller = CanvasController(
      hapticService: HapticService.instance,
      socketService: SocketService.instance,
      storageService: StorageService.instance,
    );
    
    // Hide instructions after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showInstructions = false);
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        body: Stack(
          children: [
            // Animated background
            const Positioned.fill(
              child: AnimatedBackground(),
            ),
            
            // Touch canvas
            Positioned.fill(
              child: _buildTouchCanvas(),
            ),
            
            // Touch effects layer
            Positioned.fill(
              child: _buildEffectsLayer(),
            ),
            
            // UI Overlay
            Positioned.fill(
              child: _buildUIOverlay(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTouchCanvas() {
    return Consumer<CanvasController>(
      builder: (context, controller, child) {
        return Listener(
          onPointerDown: (event) {
            final screenSize = MediaQuery.of(context).size;
            controller.onTouchDown(event.localPosition, screenSize);
            controller.onMultiTouchUpdate(
              event.pointer, 
              event.localPosition, 
              true, 
              screenSize,
            );
          },
          onPointerMove: (event) {
            final screenSize = MediaQuery.of(context).size;
            controller.onTouchMove(event.localPosition, screenSize);
          },
          onPointerUp: (event) {
            final screenSize = MediaQuery.of(context).size;
            controller.onTouchUp(event.localPosition, screenSize);
            controller.onMultiTouchUpdate(
              event.pointer, 
              event.localPosition, 
              false, 
              screenSize,
            );
          },
          onPointerCancel: (event) {
            final screenSize = MediaQuery.of(context).size;
            controller.onTouchUp(event.localPosition, screenSize);
          },
          child: Container(
            color: Colors.transparent,
            child: CustomPaint(
              painter: _TouchTrailPainter(
                points: controller.touchTrail,
                isLongPressing: controller.isLongPressing,
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEffectsLayer() {
    return Consumer<CanvasController>(
      builder: (context, controller, child) {
        final screenSize = MediaQuery.of(context).size;
        
        return Stack(
          children: [
            // Glow trail for active touch
            if (controller.touchTrail.isNotEmpty)
              GlowTrailEffect(
                points: controller.touchTrail,
                isFromPartner: false,
              ),
            
            // Ripple effects
            ...controller.rippleEffects.asMap().entries.map((entry) {
              final touch = entry.value;
              final position = Offset(
                touch.x * screenSize.width,
                touch.y * screenSize.height,
              );
              return RippleEffect(
                key: ValueKey('ripple_${touch.id}_${entry.key}'),
                position: position,
                isFromPartner: touch.isFromPartner,
                onComplete: () => controller.removeRipple(touch),
              );
            }),
            
            // Gesture effects
            ...controller.gestureEffects.asMap().entries.map((entry) {
              final gesture = entry.value;
              return GestureEffects(
                key: ValueKey('gesture_${gesture.id}_${entry.key}'),
                gesture: gesture,
                screenSize: screenSize,
                onComplete: () => controller.removeGestureEffect(gesture),
              );
            }),
            
            // Partner touch ripples
            ...controller.partnerTouches.asMap().entries.map((entry) {
              final touch = entry.value;
              final position = Offset(
                touch.x * screenSize.width,
                touch.y * screenSize.height,
              );
              return RippleEffect(
                key: ValueKey('partner_ripple_${touch.id}_${entry.key}'),
                position: position,
                isFromPartner: true,
                maxRadius: 120,
              );
            }),
            
            // Partner gesture effects
            ...controller.partnerGestures.asMap().entries.map((entry) {
              final gesture = entry.value;
              return GestureEffects(
                key: ValueKey('partner_gesture_${gesture.id}_${entry.key}'),
                gesture: gesture.copyWith(isFromPartner: true),
                screenSize: screenSize,
              );
            }),
            
            // Touch point indicator
            if (controller.touchTrail.isNotEmpty)
              TouchPointIndicator(
                position: controller.touchTrail.last,
                isActive: true,
                isFromPartner: false,
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildUIOverlay() {
    return Consumer<CanvasController>(
      builder: (context, controller, child) {
        return SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // App logo
                    const Text(
                      'Tether',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    // Connection status
                    ConnectionStatus(
                      isConnected: controller.isConnected,
                      isPartnerOnline: controller.isPartnerOnline,
                      partnerName: 'Partner',
                    ),
                  ],
                ),
              ),
              
              // Instructions (fade out)
              AnimatedOpacity(
                opacity: _showInstructions ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: _buildInstructions(),
              ),
              
              const Spacer(),
              
              // Demo mode indicator
              if (SocketService.instance.isDemoMode)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    borderRadius: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Demo Mode - Touches echo back',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Touch Gestures',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInstructionRow('👆 Tap', 'Send a quick touch'),
            _buildInstructionRow('👆👆 Double Tap', 'Send love ❤️'),
            _buildInstructionRow('👆⬆️ Swipe Up', 'Virtual high-five 🖐️'),
            _buildInstructionRow('🔄 Circle', 'Calming touch ✨'),
            _buildInstructionRow('👌 Pinch', 'Playful pinch'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInstructionRow(String gesture, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              gesture,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for touch trail
class _TouchTrailPainter extends CustomPainter {
  final List<Offset> points;
  final bool isLongPressing;
  
  _TouchTrailPainter({
    required this.points,
    required this.isLongPressing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    
    // Draw subtle trail dots
    for (int i = 0; i < points.length; i++) {
      final opacity = (i + 1) / points.length * 0.3;
      final paint = Paint()
        ..color = Color.fromRGBO(AppColors.primary.red, AppColors.primary.green, AppColors.primary.blue, opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(points[i], 3, paint);
    }
    
    // Draw long press indicator
    if (isLongPressing && points.isNotEmpty) {
      final lastPoint = points.last;
      final longPressPaint = Paint()
        ..color = Color.fromRGBO(AppColors.primary.red, AppColors.primary.green, AppColors.primary.blue, 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
      canvas.drawCircle(lastPoint, 40, longPressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TouchTrailPainter oldDelegate) {
    return oldDelegate.points.length != points.length ||
           oldDelegate.isLongPressing != isLongPressing;
  }
}
