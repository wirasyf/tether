import 'package:uuid/uuid.dart';

/// Types of special gestures with meaning
enum GestureType {
  doubleTap,    // Love ❤️
  swipeUp,      // High Five 🖐️
  circleMotion, // Calming ✨
  pinch,        // Playful pinch 👌
}

/// Represents a recognized gesture event
class GestureEvent {
  final String id;
  final GestureType type;
  final double x;  // Center X of gesture (normalized 0-1)
  final double y;  // Center Y of gesture (normalized 0-1)
  final DateTime timestamp;
  final bool isFromPartner;
  final Map<String, dynamic>? metadata;  // Additional gesture data
  
  const GestureEvent({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.timestamp,
    this.isFromPartner = false,
    this.metadata,
  });
  
  /// Create a new gesture event with auto-generated ID
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
  
  /// Create a copy with optional new values
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
  
  /// Get display name for gesture
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
    }
  }
  
  /// Get emoji for gesture
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
    }
  }
  
  /// Convert to JSON for transmission/storage
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
  
  /// Create from JSON
  factory GestureEvent.fromJson(Map<String, dynamic> json) {
    return GestureEvent(
      id: json['id'] as String,
      type: GestureType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => GestureType.doubleTap,
      ),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFromPartner: json['isFromPartner'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  
  @override
  String toString() {
    return 'GestureEvent(type: $type, x: $x, y: $y, fromPartner: $isFromPartner)';
  }
}
