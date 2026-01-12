import 'package:uuid/uuid.dart';

/// Represents a single touch event on the canvas
class TouchEvent {
  final String id;
  final double x;  // Normalized 0-1 (percentage of screen width)
  final double y;  // Normalized 0-1 (percentage of screen height)
  final TouchType type;
  final DateTime timestamp;
  final int durationMs;
  final bool isFromPartner;
  
  const TouchEvent({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    required this.timestamp,
    this.durationMs = 0,
    this.isFromPartner = false,
  });
  
  /// Create a new touch event with auto-generated ID
  factory TouchEvent.create({
    required double x,
    required double y,
    required TouchType type,
    int durationMs = 0,
    bool isFromPartner = false,
  }) {
    return TouchEvent(
      id: const Uuid().v4(),
      x: x,
      y: y,
      type: type,
      timestamp: DateTime.now(),
      durationMs: durationMs,
      isFromPartner: isFromPartner,
    );
  }
  
  /// Create a copy with optional new values
  TouchEvent copyWith({
    String? id,
    double? x,
    double? y,
    TouchType? type,
    DateTime? timestamp,
    int? durationMs,
    bool? isFromPartner,
  }) {
    return TouchEvent(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      durationMs: durationMs ?? this.durationMs,
      isFromPartner: isFromPartner ?? this.isFromPartner,
    );
  }
  
  /// Convert to JSON for transmission/storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'durationMs': durationMs,
      'isFromPartner': isFromPartner,
    };
  }
  
  /// Create from JSON
  factory TouchEvent.fromJson(Map<String, dynamic> json) {
    return TouchEvent(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      type: TouchType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TouchType.tap,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      durationMs: json['durationMs'] as int? ?? 0,
      isFromPartner: json['isFromPartner'] as bool? ?? false,
    );
  }
  
  @override
  String toString() {
    return 'TouchEvent(id: $id, x: $x, y: $y, type: $type, fromPartner: $isFromPartner)';
  }
}

/// Type of touch interaction
enum TouchType {
  tap,       // Quick single touch
  longPress, // Sustained touch
  move,      // Finger movement
  release,   // Finger lifted
}
