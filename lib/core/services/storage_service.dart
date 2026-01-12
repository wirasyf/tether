import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/touch_event.dart';
import '../../models/gesture_type.dart';

/// Storage service for Ghost Touch feature
/// Stores touch events when partner is offline for later replay
class StorageService {
  static StorageService? _instance;
  static const String _ghostTouchesKey = 'ghost_touches';
  static const String _ghostGesturesKey = 'ghost_gestures';
  static const String _userIdKey = 'user_id';
  static const String _partnerIdKey = 'partner_id';
  static const String _roomIdKey = 'room_id';
  
  SharedPreferences? _prefs;
  
  StorageService._();
  
  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }
  
  /// Initialize shared preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // ============ Ghost Touch Storage ============
  
  /// Save a touch event for ghost touch replay
  Future<void> saveGhostTouch(TouchEvent touch) async {
    final touches = await getGhostTouches();
    touches.add(touch);
    
    final jsonList = touches.map((t) => t.toJson()).toList();
    await _prefs?.setString(_ghostTouchesKey, jsonEncode(jsonList));
  }
  
  /// Save a gesture event for ghost touch replay
  Future<void> saveGhostGesture(GestureEvent gesture) async {
    final gestures = await getGhostGestures();
    gestures.add(gesture);
    
    final jsonList = gestures.map((g) => g.toJson()).toList();
    await _prefs?.setString(_ghostGesturesKey, jsonEncode(jsonList));
  }
  
  /// Get all stored ghost touches
  Future<List<TouchEvent>> getGhostTouches() async {
    final jsonString = _prefs?.getString(_ghostTouchesKey);
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => TouchEvent.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Get all stored ghost gestures
  Future<List<GestureEvent>> getGhostGestures() async {
    final jsonString = _prefs?.getString(_ghostGesturesKey);
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => GestureEvent.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Clear all ghost touches (after replay)
  Future<void> clearGhostTouches() async {
    await _prefs?.remove(_ghostTouchesKey);
    await _prefs?.remove(_ghostGesturesKey);
  }
  
  /// Get count of pending ghost touches
  Future<int> getGhostTouchCount() async {
    final touches = await getGhostTouches();
    final gestures = await getGhostGestures();
    return touches.length + gestures.length;
  }
  
  // ============ User Settings ============
  
  /// Save user ID
  Future<void> setUserId(String id) async {
    await _prefs?.setString(_userIdKey, id);
  }
  
  /// Get user ID
  String? getUserId() {
    return _prefs?.getString(_userIdKey);
  }
  
  /// Save partner ID
  Future<void> setPartnerId(String id) async {
    await _prefs?.setString(_partnerIdKey, id);
  }
  
  /// Get partner ID
  String? getPartnerId() {
    return _prefs?.getString(_partnerIdKey);
  }
  
  /// Save room ID
  Future<void> setRoomId(String id) async {
    await _prefs?.setString(_roomIdKey, id);
  }
  
  /// Get room ID
  String? getRoomId() {
    return _prefs?.getString(_roomIdKey);
  }
  
  /// Check if user has been paired
  bool isPaired() {
    return getPartnerId() != null && getRoomId() != null;
  }
  
  /// Clear all data (for logout/unpair)
  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
