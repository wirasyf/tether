import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/touch_event.dart';
import '../../models/gesture_type.dart';

/// Real-time sync service using Firebase Realtime Database
/// Enables touch and gesture synchronization between devices
class RealtimeSyncService {
  static RealtimeSyncService? _instance;
  
  late DatabaseReference _database;
  String? _roomId;
  String? _myId;
  bool _isConnected = false;
  bool _isPartnerOnline = false;
  
  // Stream controllers for incoming events
  final StreamController<TouchEvent> _touchController = StreamController<TouchEvent>.broadcast();
  final StreamController<GestureEvent> _gestureController = StreamController<GestureEvent>.broadcast();
  final StreamController<bool> _partnerStatusController = StreamController<bool>.broadcast();
  
  // Subscriptions
  StreamSubscription? _touchSubscription;
  StreamSubscription? _gestureSubscription;
  StreamSubscription? _presenceSubscription;
  Timer? _heartbeatTimer;
  
  RealtimeSyncService._();
  
  static RealtimeSyncService get instance {
    _instance ??= RealtimeSyncService._();
    return _instance!;
  }
  
  // Getters
  bool get isConnected => _isConnected;
  bool get isPartnerOnline => _isPartnerOnline;
  String? get roomId => _roomId;
  Stream<TouchEvent> get incomingTouches => _touchController.stream;
  Stream<GestureEvent> get incomingGestures => _gestureController.stream;
  Stream<bool> get partnerStatus => _partnerStatusController.stream;
  
  /// Initialize Firebase connection
  Future<void> initialize() async {
    _database = FirebaseDatabase.instance.ref();
  }
  
  /// Connect to a room for real-time sync
  Future<void> connect({required String roomId, required String myId}) async {
    _roomId = roomId;
    _myId = myId;
    
    // Set my presence
    await _setPresence(true);
    
    // Listen for touches
    _touchSubscription = _database
        .child('rooms/$roomId/touches')
        .onChildAdded
        .listen(_handleIncomingTouch);
    
    // Listen for gestures
    _gestureSubscription = _database
        .child('rooms/$roomId/gestures')
        .onChildAdded
        .listen(_handleIncomingGesture);
    
    // Listen for partner presence
    _presenceSubscription = _database
        .child('rooms/$roomId/presence')
        .onValue
        .listen(_handlePresenceChange);
    
    // Start heartbeat
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _setPresence(true);
    });
    
    _isConnected = true;
  }
  
  /// Disconnect from room
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    await _touchSubscription?.cancel();
    await _gestureSubscription?.cancel();
    await _presenceSubscription?.cancel();
    
    if (_roomId != null && _myId != null) {
      await _setPresence(false);
    }
    
    _isConnected = false;
    _isPartnerOnline = false;
    _roomId = null;
  }
  
  /// Send a touch event to partner
  Future<void> sendTouch(TouchEvent touch) async {
    if (_roomId == null || !_isConnected) return;
    
    try {
      await _database.child('rooms/$_roomId/touches').push().set({
        ...touch.toJson(),
        'senderId': _myId,
        'timestamp': ServerValue.timestamp,
      });
      
      // Clean up old touches (keep last 50)
      _cleanupOldEvents('touches');
    } catch (e) {
      debugPrint('Failed to send touch: $e');
    }
  }
  
  /// Send a gesture event to partner
  Future<void> sendGesture(GestureEvent gesture) async {
    if (_roomId == null || !_isConnected) return;
    
    try {
      await _database.child('rooms/$_roomId/gestures').push().set({
        ...gesture.toJson(),
        'senderId': _myId,
        'timestamp': ServerValue.timestamp,
      });
      
      // Clean up old gestures (keep last 20)
      _cleanupOldEvents('gestures');
    } catch (e) {
      debugPrint('Failed to send gesture: $e');
    }
  }
  
  void _handleIncomingTouch(DatabaseEvent event) {
    try {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;
      
      // Ignore my own touches
      if (data['senderId'] == _myId) return;
      
      final touch = TouchEvent.fromJson(Map<String, dynamic>.from(data));
      _touchController.add(touch.copyWith(isFromPartner: true));
    } catch (e) {
      debugPrint('Error parsing incoming touch: $e');
    }
  }
  
  void _handleIncomingGesture(DatabaseEvent event) {
    try {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;
      
      // Ignore my own gestures
      if (data['senderId'] == _myId) return;
      
      final gesture = GestureEvent.fromJson(Map<String, dynamic>.from(data));
      _gestureController.add(gesture.copyWith(isFromPartner: true));
    } catch (e) {
      debugPrint('Error parsing incoming gesture: $e');
    }
  }
  
  void _handlePresenceChange(DatabaseEvent event) {
    try {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        _isPartnerOnline = false;
        _partnerStatusController.add(false);
        return;
      }
      
      // Check if any other user is online
      bool partnerOnline = false;
      data.forEach((userId, userData) {
        if (userId != _myId && userData is Map) {
          final isOnline = userData['online'] == true;
          final lastSeen = userData['lastSeen'] as int?;
          
          // Consider online if seen in last 60 seconds
          if (isOnline || (lastSeen != null && 
              DateTime.now().millisecondsSinceEpoch - lastSeen < 60000)) {
            partnerOnline = true;
          }
        }
      });
      
      if (_isPartnerOnline != partnerOnline) {
        _isPartnerOnline = partnerOnline;
        _partnerStatusController.add(partnerOnline);
      }
    } catch (e) {
      debugPrint('Error handling presence: $e');
    }
  }
  
  Future<void> _setPresence(bool online) async {
    if (_roomId == null || _myId == null) return;
    
    try {
      await _database.child('rooms/$_roomId/presence/$_myId').set({
        'online': online,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Failed to set presence: $e');
    }
  }
  
  Future<void> _cleanupOldEvents(String eventType) async {
    try {
      final snapshot = await _database
          .child('rooms/$_roomId/$eventType')
          .orderByChild('timestamp')
          .limitToFirst(1)
          .get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        // If we have more than threshold, remove oldest
        if (data.length > (eventType == 'touches' ? 50 : 20)) {
          for (var key in data.keys) {
            await _database.child('rooms/$_roomId/$eventType/$key').remove();
            break; // Remove only one at a time
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
  
  void dispose() {
    disconnect();
    _touchController.close();
    _gestureController.close();
    _partnerStatusController.close();
  }
}
