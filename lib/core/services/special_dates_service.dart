import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

/// Special date type
enum SpecialDateType { anniversary, birthday, firstDate, firstKiss, custom }

extension SpecialDateTypeExtension on SpecialDateType {
  String get displayName {
    switch (this) {
      case SpecialDateType.anniversary:
        return 'Anniversary';
      case SpecialDateType.birthday:
        return 'Birthday';
      case SpecialDateType.firstDate:
        return 'First Date';
      case SpecialDateType.firstKiss:
        return 'First Kiss';
      case SpecialDateType.custom:
        return 'Special Day';
    }
  }

  String get emoji {
    switch (this) {
      case SpecialDateType.anniversary:
        return '💍';
      case SpecialDateType.birthday:
        return '🎂';
      case SpecialDateType.firstDate:
        return '💕';
      case SpecialDateType.firstKiss:
        return '💋';
      case SpecialDateType.custom:
        return '⭐';
    }
  }
}

/// Special date model
class SpecialDate {
  final String id;
  final String name;
  final DateTime date;
  final SpecialDateType type;

  SpecialDate({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
  });

  /// Days until next occurrence
  int get daysUntil {
    final now = DateTime.now();
    final nextOccurrence = DateTime(now.year, date.month, date.day);

    if (nextOccurrence.isBefore(now)) {
      return DateTime(
        now.year + 1,
        date.month,
        date.day,
      ).difference(now).inDays;
    }
    return nextOccurrence.difference(now).inDays;
  }

  /// Check if it's today
  bool get isToday {
    final now = DateTime.now();
    return date.month == now.month && date.day == now.day;
  }

  /// Years since the date
  int get yearsSince {
    return DateTime.now().year - date.year;
  }

  /// Get emoji from type
  String get emoji => type.emoji;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'date': date.toIso8601String(),
    'type': type.name,
  };

  factory SpecialDate.fromJson(Map<String, dynamic> json) => SpecialDate(
    id: json['id'] as String,
    name: json['name'] as String,
    date: DateTime.parse(json['date'] as String),
    type: SpecialDateType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => SpecialDateType.custom,
    ),
  );
}

/// Service for managing special dates
class SpecialDatesService extends ChangeNotifier {
  static SpecialDatesService? _instance;
  static SpecialDatesService get instance {
    _instance ??= SpecialDatesService._();
    return _instance!;
  }

  SpecialDatesService._();

  String? _roomId;
  final List<SpecialDate> _dates = [];
  StreamSubscription? _subscription;

  List<SpecialDate> get dates => List.unmodifiable(_dates);

  /// Get upcoming dates sorted by days until
  List<SpecialDate> get upcomingDates {
    final sorted = List<SpecialDate>.from(_dates);
    sorted.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    return sorted;
  }

  /// Get today's special dates
  List<SpecialDate> get todaysSpecialDates {
    return _dates.where((d) => d.isToday).toList();
  }

  Future<void> initialize({required String roomId}) async {
    _roomId = roomId;

    // Listen to changes
    _subscription = FirebaseDatabase.instance
        .ref('rooms/$roomId/specialDates')
        .onValue
        .listen(_handleDataChange);
  }

  void _handleDataChange(DatabaseEvent event) {
    try {
      final value = event.snapshot.value;
      _dates.clear();

      if (value != null && value is Map) {
        for (final entry in value.entries) {
          try {
            final data = Map<String, dynamic>.from(entry.value as Map);
            _dates.add(SpecialDate.fromJson(data));
          } catch (e) {
            debugPrint('Error parsing special date: $e');
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error handling special dates: $e');
    }
  }

  /// Add a new special date
  Future<void> addDate(SpecialDate date) async {
    if (_roomId == null) return;

    try {
      await FirebaseDatabase.instance
          .ref('rooms/$_roomId/specialDates/${date.id}')
          .set(date.toJson());
    } catch (e) {
      debugPrint('Error adding special date: $e');
    }
  }

  /// Remove a special date
  Future<void> removeDate(String dateId) async {
    if (_roomId == null) return;

    try {
      await FirebaseDatabase.instance
          .ref('rooms/$_roomId/specialDates/$dateId')
          .remove();
    } catch (e) {
      debugPrint('Error removing special date: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
