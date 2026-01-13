import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Achievement definitions
enum AchievementType {
  // Touch milestones
  firstTouch,
  touch100,
  touch500,
  touch1000,
  touch5000,

  // Gesture milestones
  firstGesture,
  gesture50,
  gesture200,

  // Streak milestones
  streak3,
  streak7,
  streak14,
  streak30,
  streak100,

  // Special
  nightOwl, // Touch at midnight
  earlyBird, // Touch at 6am
  loveExplosion, // 10 love gestures in day
  marathonSession, // 100 touches in one session
}

extension AchievementTypeExtension on AchievementType {
  String get title {
    switch (this) {
      case AchievementType.firstTouch:
        return 'First Touch';
      case AchievementType.touch100:
        return 'Century';
      case AchievementType.touch500:
        return 'High Five Hundred';
      case AchievementType.touch1000:
        return 'Thousand Hearts';
      case AchievementType.touch5000:
        return 'Touch Master';
      case AchievementType.firstGesture:
        return 'First Gesture';
      case AchievementType.gesture50:
        return 'Gesture Artist';
      case AchievementType.gesture200:
        return 'Gesture Master';
      case AchievementType.streak3:
        return 'Getting Started';
      case AchievementType.streak7:
        return 'One Week';
      case AchievementType.streak14:
        return 'Two Weeks';
      case AchievementType.streak30:
        return 'Monthly Love';
      case AchievementType.streak100:
        return 'Century Streak';
      case AchievementType.nightOwl:
        return 'Night Owl';
      case AchievementType.earlyBird:
        return 'Early Bird';
      case AchievementType.loveExplosion:
        return 'Love Explosion';
      case AchievementType.marathonSession:
        return 'Marathon';
    }
  }

  String get description {
    switch (this) {
      case AchievementType.firstTouch:
        return 'Send your first touch';
      case AchievementType.touch100:
        return 'Send 100 touches';
      case AchievementType.touch500:
        return 'Send 500 touches';
      case AchievementType.touch1000:
        return 'Send 1,000 touches';
      case AchievementType.touch5000:
        return 'Send 5,000 touches';
      case AchievementType.firstGesture:
        return 'Send your first gesture';
      case AchievementType.gesture50:
        return 'Send 50 gestures';
      case AchievementType.gesture200:
        return 'Send 200 gestures';
      case AchievementType.streak3:
        return 'Connect 3 days in a row';
      case AchievementType.streak7:
        return 'Connect 7 days in a row';
      case AchievementType.streak14:
        return 'Connect 14 days in a row';
      case AchievementType.streak30:
        return 'Connect 30 days in a row';
      case AchievementType.streak100:
        return 'Connect 100 days in a row';
      case AchievementType.nightOwl:
        return 'Touch after midnight';
      case AchievementType.earlyBird:
        return 'Touch before 7am';
      case AchievementType.loveExplosion:
        return 'Send 10 love gestures in one day';
      case AchievementType.marathonSession:
        return 'Send 100 touches in one session';
    }
  }

  String get emoji {
    switch (this) {
      case AchievementType.firstTouch:
        return '👆';
      case AchievementType.touch100:
        return '💯';
      case AchievementType.touch500:
        return '🖐️';
      case AchievementType.touch1000:
        return '💕';
      case AchievementType.touch5000:
        return '👑';
      case AchievementType.firstGesture:
        return '✨';
      case AchievementType.gesture50:
        return '🎨';
      case AchievementType.gesture200:
        return '🏆';
      case AchievementType.streak3:
        return '🔥';
      case AchievementType.streak7:
        return '📆';
      case AchievementType.streak14:
        return '⚡';
      case AchievementType.streak30:
        return '🌟';
      case AchievementType.streak100:
        return '💎';
      case AchievementType.nightOwl:
        return '🦉';
      case AchievementType.earlyBird:
        return '🐦';
      case AchievementType.loveExplosion:
        return '💥';
      case AchievementType.marathonSession:
        return '🏃';
    }
  }

  int get points {
    switch (this) {
      case AchievementType.firstTouch:
        return 10;
      case AchievementType.touch100:
        return 50;
      case AchievementType.touch500:
        return 100;
      case AchievementType.touch1000:
        return 200;
      case AchievementType.touch5000:
        return 500;
      case AchievementType.firstGesture:
        return 10;
      case AchievementType.gesture50:
        return 75;
      case AchievementType.gesture200:
        return 150;
      case AchievementType.streak3:
        return 25;
      case AchievementType.streak7:
        return 75;
      case AchievementType.streak14:
        return 150;
      case AchievementType.streak30:
        return 300;
      case AchievementType.streak100:
        return 1000;
      case AchievementType.nightOwl:
        return 50;
      case AchievementType.earlyBird:
        return 50;
      case AchievementType.loveExplosion:
        return 100;
      case AchievementType.marathonSession:
        return 100;
    }
  }
}

/// Achievement completion data
class AchievementData {
  final AchievementType type;
  final DateTime unlockedAt;

  AchievementData({required this.type, required this.unlockedAt});

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'unlockedAt': unlockedAt.toIso8601String(),
  };

  factory AchievementData.fromJson(Map<String, dynamic> json) {
    return AchievementData(
      type: AchievementType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AchievementType.firstTouch,
      ),
      unlockedAt: DateTime.parse(json['unlockedAt']),
    );
  }
}

/// Couple level based on points
enum CoupleLevel {
  newlyweds, // 0-99
  sweethearts, // 100-499
  lovebirds, // 500-1499
  soulmates, // 1500-2999
  legendary, // 3000+
}

extension CoupleLevelExtension on CoupleLevel {
  String get displayName {
    switch (this) {
      case CoupleLevel.newlyweds:
        return 'Newlyweds';
      case CoupleLevel.sweethearts:
        return 'Sweethearts';
      case CoupleLevel.lovebirds:
        return 'Lovebirds';
      case CoupleLevel.soulmates:
        return 'Soulmates';
      case CoupleLevel.legendary:
        return 'Legendary';
    }
  }

  String get emoji {
    switch (this) {
      case CoupleLevel.newlyweds:
        return '💑';
      case CoupleLevel.sweethearts:
        return '💕';
      case CoupleLevel.lovebirds:
        return '🕊️';
      case CoupleLevel.soulmates:
        return '💖';
      case CoupleLevel.legendary:
        return '👑';
    }
  }

  int get minPoints {
    switch (this) {
      case CoupleLevel.newlyweds:
        return 0;
      case CoupleLevel.sweethearts:
        return 100;
      case CoupleLevel.lovebirds:
        return 500;
      case CoupleLevel.soulmates:
        return 1500;
      case CoupleLevel.legendary:
        return 3000;
    }
  }
}

/// Service for tracking achievements
class AchievementService extends ChangeNotifier {
  static AchievementService? _instance;
  static AchievementService get instance {
    _instance ??= AchievementService._();
    return _instance!;
  }

  AchievementService._();

  List<AchievementData> _unlockedAchievements = [];
  int _sessionTouches = 0;
  int _todayLoveGestures = 0;

  List<AchievementData> get unlockedAchievements => _unlockedAchievements;
  Set<AchievementType> get unlockedTypes =>
      _unlockedAchievements.map((a) => a.type).toSet();

  int get totalPoints =>
      _unlockedAchievements.fold(0, (sum, a) => sum + a.type.points);

  CoupleLevel get currentLevel {
    final points = totalPoints;
    if (points >= 3000) return CoupleLevel.legendary;
    if (points >= 1500) return CoupleLevel.soulmates;
    if (points >= 500) return CoupleLevel.lovebirds;
    if (points >= 100) return CoupleLevel.sweethearts;
    return CoupleLevel.newlyweds;
  }

  int get pointsToNextLevel {
    final level = currentLevel;
    if (level == CoupleLevel.legendary) return 0;
    final nextIndex = CoupleLevel.values.indexOf(level) + 1;
    return CoupleLevel.values[nextIndex].minPoints - totalPoints;
  }

  Future<void> initialize() async {
    await _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('achievements');
      if (data != null) {
        final list = jsonDecode(data) as List;
        _unlockedAchievements = list
            .map((e) => AchievementData.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    }
  }

  Future<void> _saveAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'achievements',
        jsonEncode(_unlockedAchievements.map((a) => a.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving achievements: $e');
    }
  }

  /// Check and unlock achievements based on current stats
  Future<List<AchievementType>> checkAchievements({
    required int totalTouches,
    required int totalGestures,
    required int currentStreak,
  }) async {
    final newlyUnlocked = <AchievementType>[];
    _sessionTouches++;

    // Time-based achievements
    final now = DateTime.now();
    if (now.hour >= 0 && now.hour < 6) {
      if (_tryUnlock(AchievementType.nightOwl)) {
        newlyUnlocked.add(AchievementType.nightOwl);
      }
    }
    if (now.hour >= 5 && now.hour < 7) {
      if (_tryUnlock(AchievementType.earlyBird)) {
        newlyUnlocked.add(AchievementType.earlyBird);
      }
    }

    // Touch milestones
    if (totalTouches >= 1 && _tryUnlock(AchievementType.firstTouch)) {
      newlyUnlocked.add(AchievementType.firstTouch);
    }
    if (totalTouches >= 100 && _tryUnlock(AchievementType.touch100)) {
      newlyUnlocked.add(AchievementType.touch100);
    }
    if (totalTouches >= 500 && _tryUnlock(AchievementType.touch500)) {
      newlyUnlocked.add(AchievementType.touch500);
    }
    if (totalTouches >= 1000 && _tryUnlock(AchievementType.touch1000)) {
      newlyUnlocked.add(AchievementType.touch1000);
    }
    if (totalTouches >= 5000 && _tryUnlock(AchievementType.touch5000)) {
      newlyUnlocked.add(AchievementType.touch5000);
    }

    // Gesture milestones
    if (totalGestures >= 1 && _tryUnlock(AchievementType.firstGesture)) {
      newlyUnlocked.add(AchievementType.firstGesture);
    }
    if (totalGestures >= 50 && _tryUnlock(AchievementType.gesture50)) {
      newlyUnlocked.add(AchievementType.gesture50);
    }
    if (totalGestures >= 200 && _tryUnlock(AchievementType.gesture200)) {
      newlyUnlocked.add(AchievementType.gesture200);
    }

    // Streak milestones
    if (currentStreak >= 3 && _tryUnlock(AchievementType.streak3)) {
      newlyUnlocked.add(AchievementType.streak3);
    }
    if (currentStreak >= 7 && _tryUnlock(AchievementType.streak7)) {
      newlyUnlocked.add(AchievementType.streak7);
    }
    if (currentStreak >= 14 && _tryUnlock(AchievementType.streak14)) {
      newlyUnlocked.add(AchievementType.streak14);
    }
    if (currentStreak >= 30 && _tryUnlock(AchievementType.streak30)) {
      newlyUnlocked.add(AchievementType.streak30);
    }
    if (currentStreak >= 100 && _tryUnlock(AchievementType.streak100)) {
      newlyUnlocked.add(AchievementType.streak100);
    }

    // Session marathon
    if (_sessionTouches >= 100 && _tryUnlock(AchievementType.marathonSession)) {
      newlyUnlocked.add(AchievementType.marathonSession);
    }

    if (newlyUnlocked.isNotEmpty) {
      await _saveAchievements();
      notifyListeners();
    }

    return newlyUnlocked;
  }

  /// Check love gesture count for love explosion achievement
  Future<bool> checkLoveGesture() async {
    _todayLoveGestures++;
    if (_todayLoveGestures >= 10 && _tryUnlock(AchievementType.loveExplosion)) {
      await _saveAchievements();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool _tryUnlock(AchievementType type) {
    if (unlockedTypes.contains(type)) return false;
    _unlockedAchievements.add(
      AchievementData(type: type, unlockedAt: DateTime.now()),
    );
    return true;
  }

  void resetSession() {
    _sessionTouches = 0;
    _todayLoveGestures = 0;
  }
}
