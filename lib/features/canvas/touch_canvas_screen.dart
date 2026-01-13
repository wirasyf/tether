import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/stats_service.dart';
import '../../core/services/special_dates_service.dart';
import '../../core/services/heartbeat_service.dart';
import '../../core/services/partner_profile_service.dart';
import '../../core/services/mood_service.dart';
import '../../core/services/quick_message_service.dart';
import '../../core/services/relationship_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/love_notes_service.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/canvas_overlay.dart';
import '../../shared/widgets/onboarding_overlay.dart';
import '../../shared/widgets/heartbeat_button.dart';
import 'canvas_controller.dart';
import 'widgets/touch_effects.dart';
import '../gestures/gesture_effects.dart';
import '../../models/gesture_type.dart';

/// Main touch canvas screen - the virtual canvas for touch communication
class TouchCanvasScreen extends StatefulWidget {
  const TouchCanvasScreen({super.key});

  @override
  State<TouchCanvasScreen> createState() => _TouchCanvasScreenState();
}

class _TouchCanvasScreenState extends State<TouchCanvasScreen> {
  late CanvasController _controller;
  bool _showOnboarding = false;
  bool _showHeartbeatOverlay = false;
  bool _wasReceivingHeartbeat = false;

  @override
  void initState() {
    super.initState();
    _controller = CanvasController(
      hapticService: HapticService.instance,
      socketService: SocketService.instance,
      storageService: StorageService.instance,
    );

    _checkOnboarding();
    _initializeServices();

    HeartbeatService.instance.addListener(_handleHeartbeatChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    HeartbeatService.instance.removeListener(_handleHeartbeatChange);
    super.dispose();
  }

  Future<void> _checkOnboarding() async {
    final hasShown = await OnboardingOverlay.hasShownOnboarding();
    if (!hasShown) {
      if (mounted) setState(() => _showOnboarding = true);
    }
  }

  Future<void> _initializeServices() async {
    // Wait for services to be ready
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final roomId = StorageService.instance.getRoomId();
    final myId = StorageService.instance.getUserId();

    if (roomId != null && myId != null) {
      debugPrint('Initializing services for room: $roomId');
      await SpecialDatesService.instance.initialize(roomId: roomId);
      await HeartbeatService.instance.initialize(roomId: roomId, myId: myId);
      await PartnerProfileService.instance.initialize(
        roomId: roomId,
        myId: myId,
      );
      await MoodService.instance.initialize(roomId: roomId, myId: myId);
      await QuickMessageService.instance.initialize(roomId: roomId, myId: myId);
      await RelationshipService.instance.initialize(roomId: roomId, myId: myId);
      await NotificationService.instance.initialize(roomId: roomId, myId: myId);
      await LoveNotesService.instance.initialize(roomId: roomId, myId: myId);
    }
  }

  void _handleHeartbeatChange() {
    final isReceiving = HeartbeatService.instance.isReceiving;
    if (isReceiving && !_wasReceivingHeartbeat) {
      if (mounted) setState(() => _showHeartbeatOverlay = true);
    }
    _wasReceivingHeartbeat = isReceiving;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        body: Stack(
          children: [
            // Animated background
            const Positioned.fill(child: AnimatedBackground()),

            // Touch canvas
            Positioned.fill(child: _buildTouchCanvas()),

            // Touch effects layer
            Positioned.fill(child: _buildEffectsLayer()),

            // Heartbeat Received Overlay
            if (_showHeartbeatOverlay)
              Positioned.fill(
                child: HeartbeatReceivedOverlay(
                  onComplete: () {
                    if (mounted) setState(() => _showHeartbeatOverlay = false);
                  },
                ),
              ),

            // New Canvas Overlay with all features
            Positioned.fill(
              child: Consumer<CanvasController>(
                builder: (context, controller, _) {
                  return CanvasOverlay(
                    isConnected: controller.isConnected,
                    isPartnerOnline: controller.isPartnerOnline,
                    onGestureSelected: (gesture) {
                      // Trigger gesture manually
                      final event = GestureEvent.create(
                        type: gesture,
                        x: 0.5,
                        y: 0.5,
                      );
                      _controller.sendManualGesture(event);
                      StatsService.instance.recordGesture();
                    },
                  );
                },
              ),
            ),

            // Onboarding Overlay
            if (_showOnboarding)
              Positioned.fill(
                child: OnboardingOverlay(
                  onComplete: () {
                    if (mounted) setState(() => _showOnboarding = false);
                  },
                ),
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
}

/// Custom painter for touch trail
class _TouchTrailPainter extends CustomPainter {
  final List<Offset> points;
  final bool isLongPressing;

  _TouchTrailPainter({required this.points, required this.isLongPressing});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Draw subtle trail dots
    for (int i = 0; i < points.length; i++) {
      final opacity = (i + 1) / points.length * 0.3;
      final paint = Paint()
        ..color = Color.fromRGBO(
          AppColors.primary.red,
          AppColors.primary.green,
          AppColors.primary.blue,
          opacity,
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(points[i], 3, paint);
    }

    // Draw long press indicator
    if (isLongPressing && points.isNotEmpty) {
      final lastPoint = points.last;
      final longPressPaint = Paint()
        ..color = Color.fromRGBO(
          AppColors.primary.red,
          AppColors.primary.green,
          AppColors.primary.blue,
          0.3,
        )
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
