import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Love note model
class LoveNote {
  final String id;
  final String text;
  final DateTime createdAt;
  final String? mood;

  LoveNote({
    required this.id,
    required this.text,
    required this.createdAt,
    this.mood,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'mood': mood,
  };

  factory LoveNote.fromJson(Map<String, dynamic> json) => LoveNote(
    id: json['id'] as String,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    mood: json['mood'] as String?,
  );
}

/// Service for managing private love notes about partner
class LoveNotesService extends ChangeNotifier {
  static LoveNotesService? _instance;
  static LoveNotesService get instance {
    _instance ??= LoveNotesService._();
    return _instance!;
  }

  LoveNotesService._();

  final List<LoveNote> _notes = [];

  List<LoveNote> get notes => List.unmodifiable(_notes);
  List<LoveNote> get recentNotes => _notes.take(5).toList();

  Future<void> initialize() async {
    await _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('love_notes');
      if (data != null) {
        final list = jsonDecode(data) as List;
        _notes.clear();
        _notes.addAll(
          list.map((e) => LoveNote.fromJson(e as Map<String, dynamic>)),
        );
        // Sort by date, newest first
        _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading love notes: $e');
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'love_notes',
        jsonEncode(_notes.map((n) => n.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving love notes: $e');
    }
  }

  /// Add a new love note
  Future<void> addNote(String text, {String? mood}) async {
    final note = LoveNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      createdAt: DateTime.now(),
      mood: mood,
    );

    _notes.insert(0, note);
    await _saveNotes();
    notifyListeners();
  }

  /// Delete a love note
  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _saveNotes();
    notifyListeners();
  }

  /// Get notes count
  int get notesCount => _notes.length;
}
