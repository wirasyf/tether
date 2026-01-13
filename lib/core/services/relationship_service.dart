import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing relationship data including days counter
class RelationshipService extends ChangeNotifier {
  static RelationshipService? _instance;
  static RelationshipService get instance {
    _instance ??= RelationshipService._();
    return _instance!;
  }

  RelationshipService._();

  DateTime? _startDate;
  String? _roomId;
  String? _myId;
  StreamSubscription? _subscription;

  DateTime? get startDate => _startDate;

  /// Get number of days together
  int get daysTogether {
    if (_startDate == null) return 0;
    return DateTime.now().difference(_startDate!).inDays;
  }

  /// Check if relationship date is set
  bool get hasStartDate => _startDate != null;

  /// Initialize service
  Future<void> initialize({
    required String roomId,
    required String myId,
  }) async {
    _roomId = roomId;
    _myId = myId;

    // Load cached date first
    await _loadCachedDate();

    // Listen for changes from Firebase
    _subscription = FirebaseDatabase.instance
        .ref('rooms/$roomId/relationship')
        .onValue
        .listen(_handleDateChange);
  }

  Future<void> _loadCachedDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString('relationship_start_date');
      if (dateString != null) {
        _startDate = DateTime.parse(dateString);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached relationship date: $e');
    }
  }

  void _handleDateChange(DatabaseEvent event) {
    try {
      final data = event.snapshot.value;
      if (data == null) return;

      final relationshipData = Map<String, dynamic>.from(data as Map);
      final dateString = relationshipData['startDate']?.toString();

      if (dateString != null) {
        _startDate = DateTime.parse(dateString);
        _cacheDate();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling relationship date change: $e');
    }
  }

  Future<void> _cacheDate() async {
    if (_startDate == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'relationship_start_date',
        _startDate!.toIso8601String(),
      );
    } catch (e) {
      debugPrint('Error caching relationship date: $e');
    }
  }

  /// Set relationship start date
  Future<void> setStartDate(DateTime date) async {
    _startDate = date;
    notifyListeners();

    // Cache locally
    await _cacheDate();

    // Sync to Firebase
    if (_roomId != null) {
      try {
        await FirebaseDatabase.instance.ref('rooms/$_roomId/relationship').set({
          'startDate': date.toIso8601String(),
          'setBy': _myId,
          'updatedAt': ServerValue.timestamp,
        });
      } catch (e) {
        debugPrint('Error syncing relationship date: $e');
      }
    }
  }

  /// Clear relationship date
  Future<void> clearStartDate() async {
    _startDate = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('relationship_start_date');
    } catch (e) {
      debugPrint('Error clearing cached date: $e');
    }

    if (_roomId != null) {
      try {
        await FirebaseDatabase.instance
            .ref('rooms/$_roomId/relationship')
            .remove();
      } catch (e) {
        debugPrint('Error clearing relationship date: $e');
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
