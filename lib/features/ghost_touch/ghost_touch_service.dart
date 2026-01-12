import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/haptic_service.dart';
import '../../models/touch_event.dart';
import '../../models/gesture_type.dart';

/// Service to manage Ghost Touch feature
/// Records touches when partner is offline and replays them later
class GhostTouchService extends ChangeNotifier {
  final StorageService _storageService;
  final HapticService _hapticService;
  
  bool _isReplaying = false;
  int _pendingCount = 0;
  List<TouchEvent> _pendingTouches = [];
  List<GestureEvent> _pendingGestures = [];
  
  // Callbacks for UI to display effects
  Function(TouchEvent)? onReplayTouch;
  Function(GestureEvent)? onReplayGesture;
  
  GhostTouchService({
    required StorageService storageService,
    required HapticService hapticService,
  }) : _storageService = storageService,
       _hapticService = hapticService;
  
  bool get isReplaying => _isReplaying;
  int get pendingCount => _pendingCount;
  bool get hasPendingTouches => _pendingCount > 0;
  
  /// Load pending ghost touches from storage
  Future<void> loadPendingTouches() async {
    _pendingTouches = await _storageService.getGhostTouches();
    _pendingGestures = await _storageService.getGhostGestures();
    _pendingCount = _pendingTouches.length + _pendingGestures.length;
    notifyListeners();
  }
  
  /// Start replaying all pending ghost touches
  Future<void> startReplay() async {
    if (_isReplaying || _pendingCount == 0) return;
    
    _isReplaying = true;
    notifyListeners();
    
    // Notify user that ghost touches are being replayed
    await _hapticService.ghostTouchNotify();
    
    // Sort all events by timestamp
    final allEvents = <({DateTime time, dynamic event, bool isGesture})>[];
    
    for (var touch in _pendingTouches) {
      allEvents.add((time: touch.timestamp, event: touch, isGesture: false));
    }
    for (var gesture in _pendingGestures) {
      allEvents.add((time: gesture.timestamp, event: gesture, isGesture: true));
    }
    
    allEvents.sort((a, b) => a.time.compareTo(b.time));
    
    // Replay with timing
    DateTime? lastEventTime;
    
    for (var record in allEvents) {
      // Calculate delay between events
      if (lastEventTime != null) {
        var delay = record.time.difference(lastEventTime);
        // Cap delay at 2 seconds to not make replay too long
        if (delay.inMilliseconds > 2000) {
          delay = const Duration(milliseconds: 500);
        }
        // Speed up replay (2x speed)
        delay = Duration(milliseconds: delay.inMilliseconds ~/ 2);
        await Future.delayed(delay);
      }
      
      // Replay the event
      if (record.isGesture) {
        final gesture = record.event as GestureEvent;
        onReplayGesture?.call(gesture.copyWith(isFromPartner: true));
        _triggerGestureHaptic(gesture.type);
      } else {
        final touch = record.event as TouchEvent;
        onReplayTouch?.call(touch.copyWith(isFromPartner: true));
        _triggerTouchHaptic(touch.type);
      }
      
      lastEventTime = record.time;
    }
    
    // Clear stored ghost touches
    await _storageService.clearGhostTouches();
    
    _pendingTouches.clear();
    _pendingGestures.clear();
    _pendingCount = 0;
    _isReplaying = false;
    notifyListeners();
  }
  
  void _triggerTouchHaptic(TouchType type) {
    switch (type) {
      case TouchType.tap:
        _hapticService.tap();
        break;
      case TouchType.longPress:
        _hapticService.longPressStart();
        Future.delayed(const Duration(milliseconds: 300), () {
          _hapticService.stop();
        });
        break;
      case TouchType.move:
        _hapticService.touchMove();
        break;
      case TouchType.release:
        // No haptic for release
        break;
    }
  }
  
  void _triggerGestureHaptic(GestureType type) {
    switch (type) {
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
  }
  
  /// Cancel any ongoing replay
  void cancelReplay() {
    _isReplaying = false;
    notifyListeners();
  }
}

/// Widget to display ghost touch notification and trigger replay
class GhostTouchBanner extends StatelessWidget {
  final int pendingCount;
  final bool isReplaying;
  final VoidCallback onPlayPressed;
  
  const GhostTouchBanner({
    super.key,
    required this.pendingCount,
    required this.isReplaying,
    required this.onPlayPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingCount == 0 && !isReplaying) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.8),
            Colors.pink.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isReplaying ? Icons.play_arrow : Icons.touch_app,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isReplaying 
                      ? 'Playing Ghost Touches...' 
                      : 'Ghost Touches Waiting',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  isReplaying
                      ? 'Feel the love from when you were away'
                      : '$pendingCount touches from your partner',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!isReplaying)
            IconButton(
              onPressed: onPlayPressed,
              icon: const Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 36,
              ),
            ),
          if (isReplaying)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }
}
