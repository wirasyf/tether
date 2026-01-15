import 'package:uuid/uuid.dart';

/// Types of special gestures with meaning
enum GestureType {
  // Original gestures
  doubleTap, // Love ❤️
  swipeUp, // High Five 🖐️
  circleMotion, // Calming ✨
  pinch, // Playful pinch 👌
  // New gestures
  hug, // Virtual Hug 🫂
  kiss, // Send Kiss 💋
  heartbeat, // Heartbeat 💓
  thinkingOfYou, // Thinking of you 💭
  goodnight, // Goodnight 🌙
}

/// Represents a recognized gesture event
class GestureEvent {
  final String id;
  final GestureType type;
  final double x;
  final double y;
  final DateTime timestamp;
  final bool isFromPartner;
  final Map<String, dynamic>? metadata;

  const GestureEvent({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.timestamp,
    this.isFromPartner = false,
    this.metadata,
  });

  factory GestureEvent.create({
    required GestureType type,
    required double x,
    required double y,
    bool isFromPartner = false,
    Map<String, dynamic>? metadata,
  }) {
    return GestureEvent(
      id: const Uuid().v4(),
      type: type,
      x: x,
      y: y,
      timestamp: DateTime.now(),
      isFromPartner: isFromPartner,
      metadata: metadata,
    );
  }

  GestureEvent copyWith({
    String? id,
    GestureType? type,
    double? x,
    double? y,
    DateTime? timestamp,
    bool? isFromPartner,
    Map<String, dynamic>? metadata,
  }) {
    return GestureEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      timestamp: timestamp ?? this.timestamp,
      isFromPartner: isFromPartner ?? this.isFromPartner,
      metadata: metadata ?? this.metadata,
    );
  }

  String get displayName {
    switch (type) {
      case GestureType.doubleTap:
        return 'Love';
      case GestureType.swipeUp:
        return 'High Five';
      case GestureType.circleMotion:
        return 'Calming Touch';
      case GestureType.pinch:
        return 'Playful Pinch';
      case GestureType.hug:
        return 'Warm Hug';
      case GestureType.kiss:
        return 'Sweet Kiss';
      case GestureType.heartbeat:
        return 'My Heartbeat';
      case GestureType.thinkingOfYou:
        return 'Thinking of You';
      case GestureType.goodnight:
        return 'Goodnight';
    }
  }

  String get emoji {
    switch (type) {
      case GestureType.doubleTap:
        return '❤️';
      case GestureType.swipeUp:
        return '🖐️';
      case GestureType.circleMotion:
        return '✨';
      case GestureType.pinch:
        return '👌';
      case GestureType.hug:
        return '🫂';
      case GestureType.kiss:
        return '💋';
      case GestureType.heartbeat:
        return '💓';
      case GestureType.thinkingOfYou:
        return '💭';
      case GestureType.goodnight:
        return '🌙';
    }
  }

  /// Get color for gesture
  int get colorValue {
    switch (type) {
      case GestureType.doubleTap:
        return 0xFFFF1744; // Red
      case GestureType.swipeUp:
        return 0xFFFFD700; // Gold
      case GestureType.circleMotion:
        return 0xFF64B5F6; // Blue
      case GestureType.pinch:
        return 0xFFFF9800; // Orange
      case GestureType.hug:
        return 0xFFE040FB; // Purple
      case GestureType.kiss:
        return 0xFFFF69B4; // Pink
      case GestureType.heartbeat:
        return 0xFFFF4081; // Pink accent
      case GestureType.thinkingOfYou:
        return 0xFF9C27B0; // Deep purple
      case GestureType.goodnight:
        return 0xFF3F51B5; // Indigo
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'x': x,
      'y': y,
      'timestamp': timestamp.toIso8601String(),
      'isFromPartner': isFromPartner,
      'metadata': metadata,
    };
  }

  factory GestureEvent.fromJson(Map<String, dynamic> json) {
    DateTime timestamp;
    final timestampValue = json['timestamp'];
    if (timestampValue is String) {
      timestamp = DateTime.parse(timestampValue);
    } else if (timestampValue is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue);
    } else {
      timestamp = DateTime.now();
    }

    String id;
    final idValue = json['id'];
    if (idValue is String) {
      id = idValue;
    } else {
      id = idValue?.toString() ?? const Uuid().v4();
    }

    return GestureEvent(
      id: id,
      type: GestureType.values.firstWhere(
        (t) => t.name == json['type']?.toString(),
        orElse: () => GestureType.doubleTap,
      ),
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      timestamp: timestamp,
      isFromPartner: json['isFromPartner'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'GestureEvent(type: $type, x: $x, y: $y, fromPartner: $isFromPartner)';
  }
}
