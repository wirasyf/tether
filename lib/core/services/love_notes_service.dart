import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

/// Love note model
class LoveNote {
  final String id;
  final String text;
  final DateTime createdAt;
  final String? mood;
  final String senderId;
  final String senderName;

  LoveNote({
    required this.id,
    required this.text,
    required this.createdAt,
    this.mood,
    required this.senderId,
    this.senderName = 'Partner',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'mood': mood,
    'senderId': senderId,
    'senderName': senderName,
  };

  factory LoveNote.fromJson(Map<String, dynamic> json) => LoveNote(
    id: json['id'] as String,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    mood: json['mood'] as String?,
    senderId: json['senderId'] as String? ?? '',
    senderName: json['senderName'] as String? ?? 'Partner',
  );

  /// Check if this note is from me
  bool isFromMe(String myId) => senderId == myId;
}

/// Service for managing shared love notes between partners
class LoveNotesService extends ChangeNotifier {
  static LoveNotesService? _instance;
  static LoveNotesService get instance {
    _instance ??= LoveNotesService._();
    return _instance!;
  }

  LoveNotesService._();

  String? _roomId;
  String? _myId;
  String _myName = 'Me';
  final List<LoveNote> _notes = [];
  StreamSubscription? _subscription;

  List<LoveNote> get notes => List.unmodifiable(_notes);
  List<LoveNote> get recentNotes => _notes.take(5).toList();
  String? get myId => _myId;

  /// Initialize with room and user info
  Future<void> initialize({
    required String roomId,
    required String myId,
    String myName = 'Me',
  }) async {
    _roomId = roomId;
    _myId = myId;
    _myName = myName;

    // Listen for love notes changes from Firebase
    _subscription = FirebaseDatabase.instance
        .ref('rooms/$roomId/loveNotes')
        .onValue
        .listen(_handleNotesUpdate);
  }

  void _handleNotesUpdate(DatabaseEvent event) {
    try {
      final value = event.snapshot.value;
      _notes.clear();

      if (value != null && value is Map) {
        for (final entry in value.entries) {
          try {
            final data = Map<String, dynamic>.from(entry.value as Map);
            _notes.add(LoveNote.fromJson(data));
          } catch (e) {
            debugPrint('Error parsing love note: $e');
          }
        }
      }

      // Sort by date, newest first
      _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling love notes update: $e');
    }
  }

  /// Add a new love note (synced to Firebase)
  Future<void> addNote(String text, {String? mood}) async {
    if (_roomId == null || _myId == null) return;

    final note = LoveNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      createdAt: DateTime.now(),
      mood: mood,
      senderId: _myId!,
      senderName: _myName,
    );

    try {
      await FirebaseDatabase.instance
          .ref('rooms/$_roomId/loveNotes/${note.id}')
          .set(note.toJson());
    } catch (e) {
      debugPrint('Error adding love note: $e');
    }
  }

  /// Delete a love note (synced to Firebase)
  Future<void> deleteNote(String id) async {
    if (_roomId == null) return;

    try {
      await FirebaseDatabase.instance
          .ref('rooms/$_roomId/loveNotes/$id')
          .remove();
    } catch (e) {
      debugPrint('Error deleting love note: $e');
    }
  }

  /// Get notes count
  int get notesCount => _notes.length;

  /// Get my notes count
  int get myNotesCount => _notes.where((n) => n.senderId == _myId).length;

  /// Get partner's notes count
  int get partnerNotesCount => _notes.where((n) => n.senderId != _myId).length;

  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
