import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

/// Memory photo model
class MemoryPhoto {
  final String id;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;
  final String senderId;
  final String senderName;

  MemoryPhoto({
    required this.id,
    required this.imageUrl,
    this.caption,
    required this.createdAt,
    required this.senderId,
    this.senderName = 'Partner',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'imageUrl': imageUrl,
    'caption': caption,
    'createdAt': createdAt.toIso8601String(),
    'senderId': senderId,
    'senderName': senderName,
  };

  factory MemoryPhoto.fromJson(Map<String, dynamic> json) => MemoryPhoto(
    id: json['id'] as String,
    imageUrl: json['imageUrl'] as String,
    caption: json['caption'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    senderId: json['senderId'] as String? ?? '',
    senderName: json['senderName'] as String? ?? 'Partner',
  );
}

/// Service for managing shared photo memories
class PhotoMemoryService extends ChangeNotifier {
  static PhotoMemoryService? _instance;
  static PhotoMemoryService get instance {
    _instance ??= PhotoMemoryService._();
    return _instance!;
  }

  PhotoMemoryService._();

  String? _roomId;
  String? _myId;
  String _myName = 'Me';
  final List<MemoryPhoto> _photos = [];
  StreamSubscription? _subscription;

  List<MemoryPhoto> get photos => List.unmodifiable(_photos);
  int get photoCount => _photos.length;

  /// Initialize with room and user info
  Future<void> initialize({
    required String roomId,
    required String myId,
    String myName = 'Me',
  }) async {
    _roomId = roomId;
    _myId = myId;
    _myName = myName;

    // Listen for photo changes from Firebase
    _subscription = FirebaseDatabase.instance
        .ref('rooms/$roomId/photoMemories')
        .onValue
        .listen(_handlePhotosUpdate);
  }

  void _handlePhotosUpdate(DatabaseEvent event) {
    try {
      final value = event.snapshot.value;
      _photos.clear();

      if (value != null && value is Map) {
        for (final entry in value.entries) {
          try {
            final data = Map<String, dynamic>.from(entry.value as Map);
            _photos.add(MemoryPhoto.fromJson(data));
          } catch (e) {
            debugPrint('Error parsing photo: $e');
          }
        }
      }

      // Sort by date, newest first
      _photos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling photos update: $e');
    }
  }

  /// Add a new photo memory (synced to Firebase)
  Future<void> addPhoto(String imageUrl, {String? caption}) async {
    if (_roomId == null || _myId == null) return;

    final photo = MemoryPhoto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imageUrl: imageUrl,
      caption: caption,
      createdAt: DateTime.now(),
      senderId: _myId!,
      senderName: _myName,
    );

    try {
      await FirebaseDatabase.instance
          .ref('rooms/$_roomId/photoMemories/${photo.id}')
          .set(photo.toJson());
    } catch (e) {
      debugPrint('Error adding photo: $e');
    }
  }

  /// Delete a photo memory
  Future<void> deletePhoto(String id) async {
    if (_roomId == null) return;

    try {
      await FirebaseDatabase.instance
          .ref('rooms/$_roomId/photoMemories/$id')
          .remove();
    } catch (e) {
      debugPrint('Error deleting photo: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
