import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/touch_event.dart';
import '../../models/gesture_type.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/storage_service.dart';
import '../gestures/gesture_detector_service.dart';

/// Controller for the touch canvas, managing state and interactions
class CanvasController extends ChangeNotifier {
  final HapticService _hapticService;
  final SocketService _socketService;
  final StorageService _storageService;
  final GestureDetectorService _gestureService = GestureDetectorService();
  
  // Touch state
  final List<TouchEvent> _activeTouches = [];
  final List<Offset> _touchTrail = [];
  bool _isLongPressing = false;
  Timer? _longPressTimer;
  
  // Active effects to render
  final List<TouchEvent> _rippleEffects = [];
  final List<GestureEvent> _gestureEffects = [];
  
  // Incoming partner touches
  final List<TouchEvent> _partnerTouches = [];
  final List<GestureEvent> _partnerGestures = [];
  
  // Stream subscriptions
  StreamSubscription? _touchSubscription;
  StreamSubscription? _gestureSubscription;
  
  CanvasController({
    required HapticService hapticService,
    required SocketService socketService,
    required StorageService storageService,
  }) : _hapticService = hapticService,
       _socketService = socketService,
       _storageService = storageService {
    _subscribeToPartnerEvents();
  }
  
  // Getters
  List<TouchEvent> get activeTouches => List.unmodifiable(_activeTouches);
  List<Offset> get touchTrail => List.unmodifiable(_touchTrail);
  List<TouchEvent> get rippleEffects => List.unmodifiable(_rippleEffects);
  List<GestureEvent> get gestureEffects => List.unmodifiable(_gestureEffects);
  List<TouchEvent> get partnerTouches => List.unmodifiable(_partnerTouches);
  List<GestureEvent> get partnerGestures => List.unmodifiable(_partnerGestures);
  bool get isLongPressing => _isLongPressing;
  bool get isConnected => _socketService.isConnected;
  bool get isPartnerOnline => _socketService.isPartnerOnline;
  
  void _subscribeToPartnerEvents() {
    _touchSubscription = _socketService.incomingTouches.listen(_handlePartnerTouch);
    _gestureSubscription = _socketService.incomingGestures.listen(_handlePartnerGesture);
  }
  
  // ============ Touch Handling ============
  
  /// Handle touch down event
  void onTouchDown(Offset position, Size screenSize) {
    final normalizedX = position.dx / screenSize.width;
    final normalizedY = position.dy / screenSize.height;
    
    final touch = TouchEvent.create(
      x: normalizedX,
      y: normalizedY,
      type: TouchType.tap,
    );
    
    _activeTouches.add(touch);
    _touchTrail.clear();
    _touchTrail.add(position);
    
    // Trigger haptic
    _hapticService.tap();
    
    // Add ripple effect
    _rippleEffects.add(touch);
    
    // Send to partner or queue for ghost touch
    _sendOrQueueTouch(touch);
    
    // Start long press detection
    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(milliseconds: 500), () {
      _startLongPress(touch);
    });
    
    // Check for gestures (like double tap)
    final gestureEvent = _gestureService.processTouch(touch);
    if (gestureEvent != null) {
      _handleGesture(gestureEvent);
    }
    
    notifyListeners();
  }
  
  /// Handle touch move event
  void onTouchMove(Offset position, Size screenSize) {
    if (_activeTouches.isEmpty) return;
    
    final normalizedX = position.dx / screenSize.width;
    final normalizedY = position.dy / screenSize.height;
    
    final touch = TouchEvent.create(
      x: normalizedX,
      y: normalizedY,
      type: TouchType.move,
    );
    
    // Update trail
    _touchTrail.add(position);
    if (_touchTrail.length > 30) {
      _touchTrail.removeAt(0);
    }
    
    // Cancel long press if moved too much
    if (_touchTrail.length > 2) {
      final startPos = _touchTrail.first;
      final distance = (position - startPos).distance;
      if (distance > 30) {
        _cancelLongPress();
      }
    }
    
    // Light haptic for movement
    if (_touchTrail.length % 5 == 0) {
      _hapticService.touchMove();
    }
    
    // Send movement
    _sendOrQueueTouch(touch);
    
    // Check for gestures
    final gestureEvent = _gestureService.processTouch(touch);
    if (gestureEvent != null) {
      _handleGesture(gestureEvent);
    }
    
    notifyListeners();
  }
  
  /// Handle touch up event
  void onTouchUp(Offset position, Size screenSize) {
    _cancelLongPress();
    
    final normalizedX = position.dx / screenSize.width;
    final normalizedY = position.dy / screenSize.height;
    
    final touch = TouchEvent.create(
      x: normalizedX,
      y: normalizedY,
      type: TouchType.release,
    );
    
    // Send release
    _sendOrQueueTouch(touch);
    
    // Check for gestures (swipe, circle)
    final gestureEvent = _gestureService.processTouch(touch);
    if (gestureEvent != null) {
      _handleGesture(gestureEvent);
    }
    
    // Clear active touches after a delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _activeTouches.clear();
      _touchTrail.clear();
      notifyListeners();
    });
    
    notifyListeners();
  }
  
  /// Handle multi-touch for pinch detection
  void onMultiTouchUpdate(int pointerId, Offset position, bool isDown, Size screenSize) {
    final normalizedPos = Offset(
      position.dx / screenSize.width,
      position.dy / screenSize.height,
    );
    
    final gestureEvent = _gestureService.processMultiTouch(
      pointerId, 
      normalizedPos, 
      isDown,
    );
    
    if (gestureEvent != null) {
      _handleGesture(gestureEvent);
    }
  }
  
  void _startLongPress(TouchEvent touch) {
    _isLongPressing = true;
    _hapticService.longPressStart();
    
    final longPressTouch = touch.copyWith(type: TouchType.longPress);
    _sendOrQueueTouch(longPressTouch);
    
    notifyListeners();
  }
  
  void _cancelLongPress() {
    _longPressTimer?.cancel();
    if (_isLongPressing) {
      _isLongPressing = false;
      _hapticService.stop();
      notifyListeners();
    }
  }
  
  // ============ Gesture Handling ============
  
  void _handleGesture(GestureEvent gesture) {
    _gestureEffects.add(gesture);
    
    // Trigger appropriate haptic
    switch (gesture.type) {
      case GestureType.doubleTap:
        _hapticService.doubleTapLove();
        break;
      case GestureType.swipeUp:
        _hapticService.swipeUpHighFive();
        break;
      case GestureType.circleMotion:
        _hapticService.circleCalm();
        break;
      case GestureType.pinch:
        _hapticService.pinchSharp();
        break;
    }
    
    // Send to partner or queue
    _sendOrQueueGesture(gesture);
    
    notifyListeners();
  }
  
  // ============ Partner Touch Handling ============
  
  void _handlePartnerTouch(TouchEvent touch) {
    _partnerTouches.add(touch);
    
    // Trigger haptic based on touch type
    switch (touch.type) {
      case TouchType.tap:
        _hapticService.tap();
        break;
      case TouchType.longPress:
        _hapticService.longPressStart();
        break;
      case TouchType.move:
        if (_partnerTouches.length % 5 == 0) {
          _hapticService.touchMove();
        }
        break;
      case TouchType.release:
        _hapticService.stop();
        break;
    }
    
    notifyListeners();
    
    // Auto-remove partner touches after animation
    Future.delayed(const Duration(milliseconds: 800), () {
      _partnerTouches.remove(touch);
      notifyListeners();
    });
  }
  
  void _handlePartnerGesture(GestureEvent gesture) {
    _partnerGestures.add(gesture);
    
    // Trigger haptic
    switch (gesture.type) {
      case GestureType.doubleTap:
        _hapticService.doubleTapLove();
        break;
      case GestureType.swipeUp:
        _hapticService.swipeUpHighFive();
        break;
      case GestureType.circleMotion:
        _hapticService.circleCalm();
        break;
      case GestureType.pinch:
        _hapticService.pinchSharp();
        break;
    }
    
    notifyListeners();
    
    // Auto-remove after animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      _partnerGestures.remove(gesture);
      notifyListeners();
    });
  }
  
  // ============ Sending/Queueing ============
  
  void _sendOrQueueTouch(TouchEvent touch) {
    if (_socketService.isPartnerOnline) {
      _socketService.sendTouch(touch);
    } else {
      _storageService.saveGhostTouch(touch);
    }
  }
  
  void _sendOrQueueGesture(GestureEvent gesture) {
    if (_socketService.isPartnerOnline) {
      _socketService.sendGesture(gesture);
    } else {
      _storageService.saveGhostGesture(gesture);
    }
  }
  
  // ============ Effect Management ============
  
  /// Remove completed ripple effect
  void removeRipple(TouchEvent touch) {
    _rippleEffects.remove(touch);
    notifyListeners();
  }
  
  /// Remove completed gesture effect
  void removeGestureEffect(GestureEvent gesture) {
    _gestureEffects.remove(gesture);
    notifyListeners();
  }
  
  @override
  void dispose() {
    _longPressTimer?.cancel();
    _touchSubscription?.cancel();
    _gestureSubscription?.cancel();
    super.dispose();
  }
}
