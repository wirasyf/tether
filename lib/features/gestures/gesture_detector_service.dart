import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import '../../models/touch_event.dart';
import '../../models/gesture_type.dart';

/// Service to detect special gestures from touch input
class GestureDetectorService {
  // Double tap detection
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  static const _doubleTapMaxInterval = Duration(milliseconds: 300);
  static const _doubleTapMaxDistance = 50.0;
  
  // Swipe detection
  Offset? _swipeStartPosition;
  DateTime? _swipeStartTime;
  static const _swipeMinVelocity = 500.0; // pixels per second
  static const _swipeMinDistance = 100.0;
  
  // Circle detection
  final List<Offset> _circlePoints = [];
  static const _circleMinPoints = 20;
  static const _circleTolerance = 0.3; // 30% variance allowed
  
  // Pinch detection
  final Map<int, Offset> _activePointers = {};
  double? _initialPinchDistance;
  static const _pinchMinDistanceChange = 50.0;
  
  /// Process a touch event and detect gestures
  GestureEvent? processTouch(TouchEvent touch, {int? pointerId}) {
    switch (touch.type) {
      case TouchType.tap:
        return _processTap(touch);
      case TouchType.move:
        return _processMove(touch, pointerId: pointerId);
      case TouchType.release:
        return _processRelease(touch);
      case TouchType.longPress:
        return null; // Long press is handled separately
    }
  }
  
  /// Process multi-touch for pinch detection
  GestureEvent? processMultiTouch(int pointerId, Offset position, bool isDown) {
    if (isDown) {
      _activePointers[pointerId] = position;
      
      if (_activePointers.length == 2) {
        final pointers = _activePointers.values.toList();
        _initialPinchDistance = _distance(pointers[0], pointers[1]);
      }
    } else {
      final previousPointers = Map<int, Offset>.from(_activePointers);
      _activePointers.remove(pointerId);
      
      // Check for pinch gesture when second finger is released
      if (previousPointers.length == 2 && _activePointers.length == 1) {
        if (_initialPinchDistance != null) {
          final pointers = previousPointers.values.toList();
          final finalDistance = _distance(pointers[0], pointers[1]);
          final distanceChange = _initialPinchDistance! - finalDistance;
          
          if (distanceChange > _pinchMinDistanceChange) {
            final center = Offset(
              (pointers[0].dx + pointers[1].dx) / 2,
              (pointers[0].dy + pointers[1].dy) / 2,
            );
            
            _initialPinchDistance = null;
            
            return GestureEvent.create(
              type: GestureType.pinch,
              x: center.dx,
              y: center.dy,
            );
          }
        }
        _initialPinchDistance = null;
      }
    }
    
    return null;
  }
  
  /// Update pointer position for pinch tracking
  void updatePointer(int pointerId, Offset position) {
    if (_activePointers.containsKey(pointerId)) {
      _activePointers[pointerId] = position;
    }
  }
  
  GestureEvent? _processTap(TouchEvent touch) {
    final now = DateTime.now();
    final position = Offset(touch.x, touch.y);
    
    // Check for double tap
    if (_lastTapTime != null && _lastTapPosition != null) {
      final timeDiff = now.difference(_lastTapTime!);
      final distance = _distance(position, _lastTapPosition!);
      
      if (timeDiff < _doubleTapMaxInterval && distance < _doubleTapMaxDistance) {
        _lastTapTime = null;
        _lastTapPosition = null;
        
        return GestureEvent.create(
          type: GestureType.doubleTap,
          x: touch.x,
          y: touch.y,
        );
      }
    }
    
    _lastTapTime = now;
    _lastTapPosition = position;
    
    return null;
  }
  
  GestureEvent? _processMove(TouchEvent touch, {int? pointerId}) {
    final position = Offset(touch.x, touch.y);
    
    // Track swipe start
    if (_swipeStartPosition == null) {
      _swipeStartPosition = position;
      _swipeStartTime = DateTime.now();
    }
    
    // Add to circle detection
    _circlePoints.add(position);
    if (_circlePoints.length > 100) {
      _circlePoints.removeAt(0);
    }
    
    return null;
  }
  
  GestureEvent? _processRelease(TouchEvent touch) {
    GestureEvent? gesture;
    
    // Check for swipe up
    if (_swipeStartPosition != null && _swipeStartTime != null) {
      final endPosition = Offset(touch.x, touch.y);
      final dx = endPosition.dx - _swipeStartPosition!.dx;
      final dy = endPosition.dy - _swipeStartPosition!.dy;
      final distance = math.sqrt(dx * dx + dy * dy);
      
      final timeDiff = DateTime.now().difference(_swipeStartTime!);
      final velocity = distance / timeDiff.inMilliseconds * 1000;
      
      // Check if it's a vertical swipe up
      if (velocity > _swipeMinVelocity && 
          distance > _swipeMinDistance &&
          dy < 0 && // Moving up
          dy.abs() > dx.abs() * 2) { // More vertical than horizontal
        gesture = GestureEvent.create(
          type: GestureType.swipeUp,
          x: (_swipeStartPosition!.dx + endPosition.dx) / 2,
          y: (_swipeStartPosition!.dy + endPosition.dy) / 2,
        );
      }
    }
    
    // Check for circle motion
    if (gesture == null && _circlePoints.length >= _circleMinPoints) {
      if (_isCircleMotion()) {
        final center = _getCircleCenter();
        gesture = GestureEvent.create(
          type: GestureType.circleMotion,
          x: center.dx,
          y: center.dy,
        );
      }
    }
    
    // Reset tracking
    _swipeStartPosition = null;
    _swipeStartTime = null;
    _circlePoints.clear();
    
    return gesture;
  }
  
  bool _isCircleMotion() {
    if (_circlePoints.length < _circleMinPoints) return false;
    
    // Calculate center
    final center = _getCircleCenter();
    
    // Calculate average radius
    double totalRadius = 0;
    for (var point in _circlePoints) {
      totalRadius += _distance(point, center);
    }
    final avgRadius = totalRadius / _circlePoints.length;
    
    if (avgRadius < 30) return false; // Too small
    
    // Check variance
    double variance = 0;
    for (var point in _circlePoints) {
      final diff = _distance(point, center) - avgRadius;
      variance += diff * diff;
    }
    variance = math.sqrt(variance / _circlePoints.length) / avgRadius;
    
    // Check if path closes (ends near start)
    final closeDistance = _distance(_circlePoints.first, _circlePoints.last);
    final isClosed = closeDistance < avgRadius * 0.5;
    
    return variance < _circleTolerance && isClosed;
  }
  
  Offset _getCircleCenter() {
    double sumX = 0, sumY = 0;
    for (var point in _circlePoints) {
      sumX += point.dx;
      sumY += point.dy;
    }
    return Offset(sumX / _circlePoints.length, sumY / _circlePoints.length);
  }
  
  double _distance(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return math.sqrt(dx * dx + dy * dy);
  }
  
  /// Reset all gesture tracking
  void reset() {
    _lastTapTime = null;
    _lastTapPosition = null;
    _swipeStartPosition = null;
    _swipeStartTime = null;
    _circlePoints.clear();
    _activePointers.clear();
    _initialPinchDistance = null;
  }
}
