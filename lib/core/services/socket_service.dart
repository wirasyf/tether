import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/touch_event.dart';
import '../../models/gesture_type.dart';
import 'realtime_sync_service.dart';
import 'storage_service.dart';

/// Socket service that wraps RealtimeSyncService for touch synchronization
/// Provides the same interface as before but uses Firebase for real multi-device sync
class SocketService {
  static SocketService? _instance;

  bool _isDemoMode = false;
  bool _isConnected = false;
  String? _roomId;
  String? _myId; // Now nullable - will be loaded from storage

  // Demo mode echo timer
  Timer? _demoEchoTimer;
  final List<TouchEvent> _demoTouchQueue = [];
  final List<GestureEvent> _demoGestureQueue = [];

  // Stream controllers
  final StreamController<TouchEvent> _touchController =
      StreamController<TouchEvent>.broadcast();
  final StreamController<GestureEvent> _gestureController =
      StreamController<GestureEvent>.broadcast();

  // Subscriptions
  StreamSubscription? _touchSubscription;
  StreamSubscription? _gestureSubscription;

  SocketService._();

  static SocketService get instance {
    _instance ??= SocketService._();
    return _instance!;
  }

  // Getters
  bool get isConnected => _isConnected || _isDemoMode;
  bool get isPartnerOnline =>
      _isDemoMode || RealtimeSyncService.instance.isPartnerOnline;
  bool get isDemoMode => _isDemoMode;
  String? get roomId => _roomId;
  String? get myId => _myId;

  Stream<TouchEvent> get incomingTouches => _isDemoMode
      ? _touchController.stream
      : RealtimeSyncService.instance.incomingTouches;

  Stream<GestureEvent> get incomingGestures => _isDemoMode
      ? _gestureController.stream
      : RealtimeSyncService.instance.incomingGestures;

  /// Set demo mode
  void setDemoMode(bool enabled) {
    _isDemoMode = enabled;
    if (enabled) {
      _startDemoEchoLoop();
    } else {
      _demoEchoTimer?.cancel();
    }
  }

  /// Connect to a room with retry mechanism
  Future<void> connect({required String roomId, int retryCount = 0}) async {
    _roomId = roomId;

    // Load or generate persistent user ID
    _myId = StorageService.instance.getUserId();
    if (_myId == null || _myId!.isEmpty) {
      _myId = const Uuid().v4();
      await StorageService.instance.setUserId(_myId!);
      debugPrint('Generated new persistent user ID: $_myId');
    } else {
      debugPrint('Using existing user ID: $_myId');
    }

    if (_isDemoMode) {
      _isConnected = true;
      return;
    }

    try {
      await RealtimeSyncService.instance.initialize();
      await RealtimeSyncService.instance.connect(roomId: roomId, myId: _myId!);
      _isConnected = true;
      debugPrint('Connected to room: $roomId with user: $_myId');
    } catch (e) {
      debugPrint('Failed to connect to room (attempt ${retryCount + 1}): $e');

      // Retry with exponential backoff (max 3 retries)
      if (retryCount < 3) {
        final delay = Duration(milliseconds: 500 * (retryCount + 1));
        debugPrint('Retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
        return connect(roomId: roomId, retryCount: retryCount + 1);
      }

      // Fall back to demo mode after all retries failed
      debugPrint('All retries failed. Falling back to demo mode.');
      _isDemoMode = true;
      _isConnected = true;
      _startDemoEchoLoop();
    }
  }

  /// Disconnect from room
  Future<void> disconnect() async {
    _demoEchoTimer?.cancel();
    await RealtimeSyncService.instance.disconnect();
    _isConnected = false;
    _roomId = null;
  }

  /// Send a touch event
  void sendTouch(TouchEvent touch) {
    if (_isDemoMode) {
      // Queue for echo in demo mode
      _demoTouchQueue.add(touch);
    } else {
      // Send via Firebase
      RealtimeSyncService.instance.sendTouch(touch);
    }
  }

  /// Send a gesture event
  void sendGesture(GestureEvent gesture) {
    if (_isDemoMode) {
      // Queue for echo in demo mode
      _demoGestureQueue.add(gesture);
    } else {
      // Send via Firebase
      RealtimeSyncService.instance.sendGesture(gesture);
    }
  }

  void _startDemoEchoLoop() {
    _demoEchoTimer?.cancel();
    _demoEchoTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // Echo touches with slight delay
      if (_demoTouchQueue.isNotEmpty) {
        final touch = _demoTouchQueue.removeAt(0);
        // Emit as partner touch with slight offset
        Future.delayed(const Duration(milliseconds: 300), () {
          _touchController.add(
            touch.copyWith(
              isFromPartner: true,
              x: touch.x + 0.02, // Slight offset
              y: touch.y + 0.02,
            ),
          );
        });
      }

      // Echo gestures
      if (_demoGestureQueue.isNotEmpty) {
        final gesture = _demoGestureQueue.removeAt(0);
        Future.delayed(const Duration(milliseconds: 500), () {
          _gestureController.add(gesture.copyWith(isFromPartner: true));
        });
      }
    });
  }

  void dispose() {
    _demoEchoTimer?.cancel();
    _touchController.close();
    _gestureController.close();
    _touchSubscription?.cancel();
    _gestureSubscription?.cancel();
  }
}
