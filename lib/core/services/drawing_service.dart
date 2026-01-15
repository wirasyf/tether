import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

/// Drawing stroke model
class DrawingStroke {
  final String id;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final String senderId;
  final DateTime createdAt;

  DrawingStroke({
    required this.id,
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.senderId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    'color': color.value,
    'strokeWidth': strokeWidth,
    'senderId': senderId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    final pointsList = (json['points'] as List).map((p) {
      final point = Map<String, dynamic>.from(p as Map);
      return Offset(
        (point['x'] as num).toDouble(),
        (point['y'] as num).toDouble(),
      );
    }).toList();

    return DrawingStroke(
      id: json['id'] as String,
      points: pointsList,
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      senderId: json['senderId'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isFromPartner => senderId.isNotEmpty;
}

/// Service for real-time shared drawing canvas
class DrawingService extends ChangeNotifier {
  static DrawingService? _instance;
  static DrawingService get instance {
    _instance ??= DrawingService._();
    return _instance!;
  }

  DrawingService._();

  String? _roomId;
  String? _myId;
  final List<DrawingStroke> _strokes = [];
  DrawingStroke? _currentStroke;
  StreamSubscription? _subscription;

  // Drawing settings
  Color _currentColor = const Color(0xFFFF6B9D);
  double _currentStrokeWidth = 4.0;

  List<DrawingStroke> get strokes => List.unmodifiable(_strokes);
  DrawingStroke? get currentStroke => _currentStroke;
  Color get currentColor => _currentColor;
  double get currentStrokeWidth => _currentStrokeWidth;

  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _currentStrokeWidth = width;
    notifyListeners();
  }

  /// Initialize with room and user info
  Future<void> initialize({
    required String roomId,
    required String myId,
  }) async {
    _roomId = roomId;
    _myId = myId;

    // Listen for drawing changes from Firebase
    _subscription = FirebaseDatabase.instance
        .ref('rooms/$roomId/drawings')
        .onValue
        .listen(_handleDrawingsUpdate);
  }

  void _handleDrawingsUpdate(DatabaseEvent event) {
    try {
      final value = event.snapshot.value;
      _strokes.clear();

      if (value != null && value is Map) {
        for (final entry in value.entries) {
          try {
            final data = Map<String, dynamic>.from(entry.value as Map);
            _strokes.add(DrawingStroke.fromJson(data));
          } catch (e) {
            debugPrint('Error parsing stroke: $e');
          }
        }
      }

      // Sort by creation time
      _strokes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling drawings update: $e');
    }
  }

  /// Start a new stroke
  void startStroke(Offset point) {
    _currentStroke = DrawingStroke(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      points: [point],
      color: _currentColor,
      strokeWidth: _currentStrokeWidth,
      senderId: _myId ?? '',
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Add point to current stroke
  void addPoint(Offset point) {
    if (_currentStroke == null) return;

    _currentStroke = DrawingStroke(
      id: _currentStroke!.id,
      points: [..._currentStroke!.points, point],
      color: _currentStroke!.color,
      strokeWidth: _currentStroke!.strokeWidth,
      senderId: _currentStroke!.senderId,
      createdAt: _currentStroke!.createdAt,
    );
    notifyListeners();
  }

  /// End current stroke and sync to Firebase
  Future<void> endStroke() async {
    if (_currentStroke == null || _roomId == null) return;

    final stroke = _currentStroke!;
    _currentStroke = null;

    try {
      await FirebaseDatabase.instance
          .ref('rooms/$_roomId/drawings/${stroke.id}')
          .set(stroke.toJson());
    } catch (e) {
      debugPrint('Error saving stroke: $e');
    }
  }

  /// Clear all drawings
  Future<void> clearCanvas() async {
    if (_roomId == null) return;

    try {
      await FirebaseDatabase.instance.ref('rooms/$_roomId/drawings').remove();
    } catch (e) {
      debugPrint('Error clearing canvas: $e');
    }
  }

  /// Undo last stroke (my strokes only)
  Future<void> undoLastStroke() async {
    if (_roomId == null || _myId == null) return;

    final myStrokes = _strokes.where((s) => s.senderId == _myId).toList();
    if (myStrokes.isEmpty) return;

    final lastStroke = myStrokes.last;
    try {
      await FirebaseDatabase.instance
          .ref('rooms/$_roomId/drawings/${lastStroke.id}')
          .remove();
    } catch (e) {
      debugPrint('Error undoing stroke: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
