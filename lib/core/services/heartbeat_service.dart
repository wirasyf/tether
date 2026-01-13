import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';

/// Heartbeat sharing service - share your heartbeat rhythm with partner
class HeartbeatService extends ChangeNotifier {
  static HeartbeatService? _instance;
  static HeartbeatService get instance {
    _instance ??= HeartbeatService._();
    return _instance!;
  }

  HeartbeatService._();

  String? _roomId;
  String? _myId;
  StreamSubscription? _subscription;

  bool _isSending = false;
  bool _isReceiving = false;
  int _partnerBpm = 0;
  DateTime? _lastPartnerBeat;

  bool get isSending => _isSending;
  bool get isReceiving => _isReceiving;
  int get partnerBpm => _partnerBpm;
  DateTime? get lastPartnerBeat => _lastPartnerBeat;

  final StreamController<int> _beatController =
      StreamController<int>.broadcast();
  Stream<int> get partnerBeats => _beatController.stream;

  Future<void> initialize({
    required String roomId,
    required String myId,
  }) async {
    _roomId = roomId;
    _myId = myId;

    // Listen for partner's heartbeat
    _subscription = FirebaseDatabase.instance
        .ref('rooms/$roomId/heartbeat')
        .onValue
        .listen(_handleHeartbeat);
  }

  void _handleHeartbeat(DatabaseEvent event) {
    try {
      final value = event.snapshot.value;
      if (value == null) {
        _isReceiving = false;
        notifyListeners();
        return;
      }

      final data = Map<String, dynamic>.from(value as Map);

      // Ignore my own heartbeat
      if (data['senderId'] == _myId) return;

      _partnerBpm = (data['bpm'] as num?)?.toInt() ?? 72;
      _lastPartnerBeat = DateTime.now();
      _isReceiving = true;

      _beatController.add(_partnerBpm);

      // Trigger haptic for heartbeat feel
      _triggerHeartbeatHaptic();

      notifyListeners();
    } catch (e) {
      debugPrint('Error handling heartbeat: $e');
    }
  }

  void _triggerHeartbeatHaptic() {
    // Pattern: strong-weak like real heartbeat
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 150), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Start sharing your heartbeat (simulated or from sensor)
  Future<void> startSharing({int bpm = 72}) async {
    if (_roomId == null || _myId == null) return;

    _isSending = true;
    notifyListeners();

    try {
      await FirebaseDatabase.instance.ref('rooms/$_roomId/heartbeat').set({
        'senderId': _myId,
        'bpm': bpm,
        'timestamp': ServerValue.timestamp,
        'active': true,
      });
    } catch (e) {
      debugPrint('Error starting heartbeat: $e');
      _isSending = false;
      notifyListeners();
    }
  }

  /// Stop sharing heartbeat
  Future<void> stopSharing() async {
    if (_roomId == null) return;

    _isSending = false;
    notifyListeners();

    try {
      await FirebaseDatabase.instance.ref('rooms/$_roomId/heartbeat').remove();
    } catch (e) {
      debugPrint('Error stopping heartbeat: $e');
    }
  }

  /// Send a single heartbeat pulse
  Future<void> sendPulse() async {
    if (_roomId == null || _myId == null) return;

    try {
      await FirebaseDatabase.instance.ref('rooms/$_roomId/heartbeat').set({
        'senderId': _myId,
        'bpm': 72,
        'timestamp': ServerValue.timestamp,
        'pulse': true,
      });

      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Error sending pulse: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _beatController.close();
    super.dispose();
  }
}
