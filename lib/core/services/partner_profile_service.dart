import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Partner profile model
class PartnerProfile {
  final String id;
  final String name;
  final String? avatarEmoji;
  final String? timezone;
  final DateTime? lastSeen;
  final bool isOnline;

  PartnerProfile({
    required this.id,
    required this.name,
    this.avatarEmoji,
    this.timezone,
    this.lastSeen,
    this.isOnline = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarEmoji': avatarEmoji,
    'timezone': timezone,
    'lastSeen': lastSeen?.millisecondsSinceEpoch,
    'isOnline': isOnline,
  };

  factory PartnerProfile.fromJson(Map<String, dynamic> json) => PartnerProfile(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Partner',
    avatarEmoji: json['avatarEmoji'] as String?,
    timezone: json['timezone'] as String?,
    lastSeen: json['lastSeen'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] as int)
        : null,
    isOnline: json['isOnline'] as bool? ?? false,
  );
}

/// Service for managing partner profiles
class PartnerProfileService extends ChangeNotifier {
  static PartnerProfileService? _instance;
  static PartnerProfileService get instance {
    _instance ??= PartnerProfileService._();
    return _instance!;
  }

  PartnerProfileService._();

  String? _roomId;
  String? _myId;

  PartnerProfile? _myProfile;
  PartnerProfile? _partnerProfile;
  DateTime? _relationshipStart;

  PartnerProfile? get myProfile => _myProfile;
  PartnerProfile? get partnerProfile => _partnerProfile;
  DateTime? get relationshipStart => _relationshipStart;

  /// Days together
  int get daysTogether {
    if (_relationshipStart == null) return 0;
    return DateTime.now().difference(_relationshipStart!).inDays;
  }

  Future<void> initialize({
    required String roomId,
    required String myId,
  }) async {
    _roomId = roomId;
    _myId = myId;

    // Load my profile
    await _loadMyProfile();

    // Listen to partner's profile
    FirebaseDatabase.instance
        .ref('rooms/$roomId/profiles')
        .onValue
        .listen(_handleProfilesUpdate);

    // Listen to relationship start date
    final startSnapshot = await FirebaseDatabase.instance
        .ref('rooms/$roomId/relationshipStart')
        .get();
    if (startSnapshot.exists) {
      _relationshipStart = DateTime.fromMillisecondsSinceEpoch(
        startSnapshot.value as int,
      );
    }

    // Update presence
    _updatePresence(true);
  }

  void _handleProfilesUpdate(DatabaseEvent event) {
    try {
      final value = event.snapshot.value;
      if (value == null) return;

      final profiles = Map<String, dynamic>.from(value as Map);

      for (final entry in profiles.entries) {
        if (entry.key != _myId) {
          _partnerProfile = PartnerProfile.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing profiles: $e');
    }
  }

  Future<void> _loadMyProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('my_name') ?? 'Me';
      final emoji = prefs.getString('my_avatar_emoji') ?? '💕';

      _myProfile = PartnerProfile(
        id: _myId ?? '',
        name: name,
        avatarEmoji: emoji,
        timezone: DateTime.now().timeZoneName,
        isOnline: true,
      );

      // Sync to Firebase
      if (_roomId != null && _myId != null) {
        await FirebaseDatabase.instance
            .ref('rooms/$_roomId/profiles/$_myId')
            .set(_myProfile!.toJson());
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  /// Update my name
  Future<void> updateName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_name', name);

    _myProfile = PartnerProfile(
      id: _myProfile?.id ?? _myId ?? '',
      name: name,
      avatarEmoji: _myProfile?.avatarEmoji,
      timezone: _myProfile?.timezone,
      isOnline: true,
    );

    if (_roomId != null && _myId != null) {
      await FirebaseDatabase.instance
          .ref('rooms/$_roomId/profiles/$_myId')
          .update({'name': name});
    }

    notifyListeners();
  }

  /// Update my avatar emoji
  Future<void> updateAvatar(String emoji) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_avatar_emoji', emoji);

    _myProfile = PartnerProfile(
      id: _myProfile?.id ?? _myId ?? '',
      name: _myProfile?.name ?? 'Me',
      avatarEmoji: emoji,
      timezone: _myProfile?.timezone,
      isOnline: true,
    );

    if (_roomId != null && _myId != null) {
      await FirebaseDatabase.instance
          .ref('rooms/$_roomId/profiles/$_myId')
          .update({'avatarEmoji': emoji});
    }

    notifyListeners();
  }

  /// Set relationship start date
  Future<void> setRelationshipStart(DateTime date) async {
    _relationshipStart = date;

    if (_roomId != null) {
      await FirebaseDatabase.instance
          .ref('rooms/$_roomId/relationshipStart')
          .set(date.millisecondsSinceEpoch);
    }

    notifyListeners();
  }

  void _updatePresence(bool online) {
    if (_roomId == null || _myId == null) return;

    FirebaseDatabase.instance.ref('rooms/$_roomId/profiles/$_myId').update({
      'isOnline': online,
      'lastSeen': ServerValue.timestamp,
    });
  }

  void dispose() {
    _updatePresence(false);
    super.dispose();
  }
}
