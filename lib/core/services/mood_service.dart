import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available mood types
enum MoodType {
  happy,
  love,
  missYou,
  relaxed,
  excited,
  tired,
  thinking,
  grateful,
}

/// Extension for mood display properties
extension MoodTypeExtension on MoodType {
  String get emoji {
    switch (this) {
      case MoodType.happy:
        return '😊';
      case MoodType.love:
        return '🥰';
      case MoodType.missYou:
        return '🥺';
      case MoodType.relaxed:
        return '😌';
      case MoodType.excited:
        return '🤩';
      case MoodType.tired:
        return '😴';
      case MoodType.thinking:
        return '🤔';
      case MoodType.grateful:
        return '🙏';
    }
  }

  String get displayName {
    switch (this) {
      case MoodType.happy:
        return 'Happy';
      case MoodType.love:
        return 'In Love';
      case MoodType.missYou:
        return 'Miss You';
      case MoodType.relaxed:
        return 'Relaxed';
      case MoodType.excited:
        return 'Excited';
      case MoodType.tired:
        return 'Tired';
      case MoodType.thinking:
        return 'Thinking of You';
      case MoodType.grateful:
        return 'Grateful';
    }
  }

  int get primaryColorValue {
    switch (this) {
      case MoodType.happy:
        return 0xFFFFD700; // Gold
      case MoodType.love:
        return 0xFFFF69B4; // Pink
      case MoodType.missYou:
        return 0xFF9C27B0; // Purple
      case MoodType.relaxed:
        return 0xFF4FC3F7; // Light blue
      case MoodType.excited:
        return 0xFFFF5722; // Orange
      case MoodType.tired:
        return 0xFF3F51B5; // Indigo
      case MoodType.thinking:
        return 0xFFE040FB; // Magenta
      case MoodType.grateful:
        return 0xFF66BB6A; // Green
    }
  }

  int get secondaryColorValue {
    switch (this) {
      case MoodType.happy:
        return 0xFFFFA726;
      case MoodType.love:
        return 0xFFE91E63;
      case MoodType.missYou:
        return 0xFF7B1FA2;
      case MoodType.relaxed:
        return 0xFF29B6F6;
      case MoodType.excited:
        return 0xFFFF9800;
      case MoodType.tired:
        return 0xFF303F9F;
      case MoodType.thinking:
        return 0xFFAB47BC;
      case MoodType.grateful:
        return 0xFF43A047;
    }
  }
}

/// Service for managing mood state and syncing with partner
class MoodService extends ChangeNotifier {
  static MoodService? _instance;
  static MoodService get instance {
    _instance ??= MoodService._();
    return _instance!;
  }

  MoodService._();

  MoodType? _myMood;
  MoodType? _partnerMood;
  DateTime? _myMoodTime;
  DateTime? _partnerMoodTime;

  String? _roomId;
  String? _myId;
  StreamSubscription? _moodSubscription;

  // Getters
  MoodType? get myMood => _myMood;
  MoodType? get partnerMood => _partnerMood;
  DateTime? get myMoodTime => _myMoodTime;
  DateTime? get partnerMoodTime => _partnerMoodTime;

  /// Initialize mood service
  Future<void> initialize({
    required String roomId,
    required String myId,
  }) async {
    _roomId = roomId;
    _myId = myId;

    // Load cached mood
    await _loadCachedMood();

    // Listen for partner mood changes
    _moodSubscription = FirebaseDatabase.instance
        .ref('rooms/$roomId/moods')
        .onValue
        .listen(_handleMoodChange);
  }

  Future<void> _loadCachedMood() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final moodName = prefs.getString('my_mood');
      if (moodName != null) {
        _myMood = MoodType.values.firstWhere(
          (m) => m.name == moodName,
          orElse: () => MoodType.happy,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached mood: $e');
    }
  }

  void _handleMoodChange(DatabaseEvent event) {
    try {
      final data = event.snapshot.value;
      if (data == null) return;

      final moodsData = Map<String, dynamic>.from(data as Map);

      moodsData.forEach((userId, moodData) {
        if (userId != _myId && moodData is Map) {
          final moodName = moodData['mood']?.toString();
          final timestamp = moodData['timestamp'];

          if (moodName != null) {
            _partnerMood = MoodType.values.firstWhere(
              (m) => m.name == moodName,
              orElse: () => MoodType.happy,
            );

            if (timestamp is int) {
              _partnerMoodTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            }

            notifyListeners();
          }
        }
      });
    } catch (e) {
      debugPrint('Error handling mood change: $e');
    }
  }

  /// Set my mood and sync to Firebase
  Future<void> setMood(MoodType mood) async {
    _myMood = mood;
    _myMoodTime = DateTime.now();
    notifyListeners();

    // Cache locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('my_mood', mood.name);
    } catch (e) {
      debugPrint('Error caching mood: $e');
    }

    // Sync to Firebase
    if (_roomId != null && _myId != null) {
      try {
        await FirebaseDatabase.instance.ref('rooms/$_roomId/moods/$_myId').set({
          'mood': mood.name,
          'timestamp': ServerValue.timestamp,
        });
      } catch (e) {
        debugPrint('Error syncing mood: $e');
      }
    }
  }

  /// Clear my mood
  Future<void> clearMood() async {
    _myMood = null;
    _myMoodTime = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('my_mood');
    } catch (e) {
      debugPrint('Error clearing cached mood: $e');
    }

    if (_roomId != null && _myId != null) {
      try {
        await FirebaseDatabase.instance
            .ref('rooms/$_roomId/moods/$_myId')
            .remove();
      } catch (e) {
        debugPrint('Error clearing mood: $e');
      }
    }
  }

  void dispose() {
    _moodSubscription?.cancel();
    super.dispose();
  }
}
