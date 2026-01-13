import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Statistics for touch interactions
class TouchStats {
  final int todayTouches;
  final int todayGestures;
  final int weekTouches;
  final int weekGestures;
  final int totalTouches;
  final int totalGestures;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;

  const TouchStats({
    this.todayTouches = 0,
    this.todayGestures = 0,
    this.weekTouches = 0,
    this.weekGestures = 0,
    this.totalTouches = 0,
    this.totalGestures = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
  });

  TouchStats copyWith({
    int? todayTouches,
    int? todayGestures,
    int? weekTouches,
    int? weekGestures,
    int? totalTouches,
    int? totalGestures,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
  }) {
    return TouchStats(
      todayTouches: todayTouches ?? this.todayTouches,
      todayGestures: todayGestures ?? this.todayGestures,
      weekTouches: weekTouches ?? this.weekTouches,
      weekGestures: weekGestures ?? this.weekGestures,
      totalTouches: totalTouches ?? this.totalTouches,
      totalGestures: totalGestures ?? this.totalGestures,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'todayTouches': todayTouches,
    'todayGestures': todayGestures,
    'weekTouches': weekTouches,
    'weekGestures': weekGestures,
    'totalTouches': totalTouches,
    'totalGestures': totalGestures,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastActiveDate': lastActiveDate?.toIso8601String(),
  };

  factory TouchStats.fromJson(Map<String, dynamic> json) => TouchStats(
    todayTouches: json['todayTouches'] ?? 0,
    todayGestures: json['todayGestures'] ?? 0,
    weekTouches: json['weekTouches'] ?? 0,
    weekGestures: json['weekGestures'] ?? 0,
    totalTouches: json['totalTouches'] ?? 0,
    totalGestures: json['totalGestures'] ?? 0,
    currentStreak: json['currentStreak'] ?? 0,
    longestStreak: json['longestStreak'] ?? 0,
    lastActiveDate: json['lastActiveDate'] != null
        ? DateTime.parse(json['lastActiveDate'])
        : null,
  );
}

/// Service for tracking touch statistics
class StatsService extends ChangeNotifier {
  static StatsService? _instance;
  static StatsService get instance {
    _instance ??= StatsService._();
    return _instance!;
  }

  StatsService._();

  TouchStats _stats = const TouchStats();
  TouchStats get stats => _stats;

  static const String _statsKey = 'touch_stats';
  static const String _dailyHistoryKey = 'daily_history';

  // Daily history for charts (last 7 days)
  Map<String, int> _dailyTouches = {};
  Map<String, int> get dailyTouches => _dailyTouches;

  /// Initialize stats service
  Future<void> initialize() async {
    await _loadStats();
    _checkNewDay();
  }

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load main stats
      final statsJson = prefs.getString(_statsKey);
      if (statsJson != null) {
        _stats = TouchStats.fromJson(jsonDecode(statsJson));
      }

      // Load daily history
      final historyJson = prefs.getString(_dailyHistoryKey);
      if (historyJson != null) {
        final decoded = jsonDecode(historyJson) as Map<String, dynamic>;
        _dailyTouches = decoded.map((k, v) => MapEntry(k, v as int));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  void _checkNewDay() {
    final today = DateTime.now();
    final todayKey = _dateKey(today);

    if (_stats.lastActiveDate != null) {
      final lastKey = _dateKey(_stats.lastActiveDate!);

      if (todayKey != lastKey) {
        // Save yesterday's data to history
        _dailyTouches[lastKey] = _stats.todayTouches;

        // Keep only last 7 days
        _cleanupHistory();

        // Reset today's counts
        _stats = _stats.copyWith(todayTouches: 0, todayGestures: 0);

        // Check streak
        final daysDiff = today.difference(_stats.lastActiveDate!).inDays;
        if (daysDiff > 1) {
          // Streak broken
          _stats = _stats.copyWith(currentStreak: 0);
        }
      }
    }
  }

  void _cleanupHistory() {
    if (_dailyTouches.length > 7) {
      final sortedKeys = _dailyTouches.keys.toList()..sort();
      while (sortedKeys.length > 7) {
        _dailyTouches.remove(sortedKeys.removeAt(0));
      }
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Record a touch event
  Future<void> recordTouch() async {
    final today = DateTime.now();
    final isNewDay =
        _stats.lastActiveDate == null ||
        _dateKey(_stats.lastActiveDate!) != _dateKey(today);

    int newStreak = _stats.currentStreak;

    if (isNewDay) {
      if (_stats.lastActiveDate != null) {
        final daysDiff = today.difference(_stats.lastActiveDate!).inDays;
        if (daysDiff == 1) {
          newStreak = _stats.currentStreak + 1;
        } else if (daysDiff > 1) {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }
    }

    _stats = _stats.copyWith(
      todayTouches: (isNewDay ? 0 : _stats.todayTouches) + 1,
      weekTouches: _stats.weekTouches + 1,
      totalTouches: _stats.totalTouches + 1,
      currentStreak: newStreak,
      longestStreak: newStreak > _stats.longestStreak
          ? newStreak
          : _stats.longestStreak,
      lastActiveDate: today,
    );

    notifyListeners();
    await _saveStats();
  }

  /// Record a gesture event
  Future<void> recordGesture() async {
    _stats = _stats.copyWith(
      todayGestures: _stats.todayGestures + 1,
      weekGestures: _stats.weekGestures + 1,
      totalGestures: _stats.totalGestures + 1,
      lastActiveDate: DateTime.now(),
    );

    notifyListeners();
    await _saveStats();
  }

  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_statsKey, jsonEncode(_stats.toJson()));
      await prefs.setString(_dailyHistoryKey, jsonEncode(_dailyTouches));
    } catch (e) {
      debugPrint('Error saving stats: $e');
    }
  }

  /// Get daily touch count for last N days
  List<int> getDailyTouchesForChart({int days = 7}) {
    final result = <int>[];
    final today = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final key = _dateKey(date);

      if (i == 0) {
        result.add(_stats.todayTouches);
      } else {
        result.add(_dailyTouches[key] ?? 0);
      }
    }

    return result;
  }

  /// Reset all statistics
  Future<void> resetStats() async {
    _stats = const TouchStats();
    _dailyTouches.clear();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_statsKey);
      await prefs.remove(_dailyHistoryKey);
    } catch (e) {
      debugPrint('Error resetting stats: $e');
    }
  }
}
