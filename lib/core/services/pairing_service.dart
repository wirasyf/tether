import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:share_plus/share_plus.dart';
import 'storage_service.dart';

/// Service for managing persistent pairing codes
/// Codes are stored in Firebase and linked to user accounts
class PairingService extends ChangeNotifier {
  static PairingService? _instance;
  static PairingService get instance {
    _instance ??= PairingService._();
    return _instance!;
  }

  PairingService._();

  String? _myPairingCode;
  String? _partnerId;
  String? _partnerName;
  bool _isConnecting = false;
  String? _error;
  PairingStatus _status = PairingStatus.disconnected;

  // Getters
  String? get myPairingCode => _myPairingCode;
  String? get partnerId => _partnerId;
  String? get partnerName => _partnerName;
  bool get isConnecting => _isConnecting;
  String? get error => _error;
  PairingStatus get status => _status;
  bool get hasPairing => _myPairingCode != null;

  /// Generate or retrieve persistent pairing code
  Future<String> getOrCreatePairingCode() async {
    // Check if we already have a code saved
    final existingCode = StorageService.instance.getPairingCode();
    if (existingCode != null && existingCode.isNotEmpty) {
      _myPairingCode = existingCode;
      notifyListeners();
      return existingCode;
    }

    // Generate new 6-character code
    final code = _generateCode();

    // Save locally
    await StorageService.instance.setPairingCode(code);

    // Register in Firebase
    await _registerCodeInFirebase(code);

    _myPairingCode = code;
    notifyListeners();
    return code;
  }

  /// Generate a unique 6-character pairing code
  String _generateCode() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed I,O,0,1 for clarity
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    int seed = random;

    for (int i = 0; i < 6; i++) {
      code += chars[seed % chars.length];
      seed = (seed ~/ chars.length) + (seed % 17);
    }

    return code;
  }

  /// Register code in Firebase for discovery
  Future<void> _registerCodeInFirebase(String code) async {
    final userId = StorageService.instance.getUserId();
    if (userId == null) return;

    try {
      await FirebaseDatabase.instance.ref('pairing_codes/$code').set({
        'ownerId': userId,
        'createdAt': ServerValue.timestamp,
        'active': true,
      });
    } catch (e) {
      debugPrint('Error registering pairing code: $e');
    }
  }

  /// Join partner's room using their code
  Future<bool> joinWithCode(String partnerCode) async {
    _isConnecting = true;
    _error = null;
    _status = PairingStatus.connecting;
    notifyListeners();

    try {
      // Look up the code in Firebase
      final snapshot = await FirebaseDatabase.instance
          .ref('pairing_codes/${partnerCode.toUpperCase()}')
          .get();

      if (!snapshot.exists) {
        _error = 'Invalid code. Please check and try again.';
        _status = PairingStatus.error;
        _isConnecting = false;
        notifyListeners();
        return false;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final partnerId = data['ownerId'] as String?;

      if (partnerId == null) {
        _error = 'Code is not properly configured.';
        _status = PairingStatus.error;
        _isConnecting = false;
        notifyListeners();
        return false;
      }

      // Create a room ID from both codes (sorted for consistency)
      final myCode = await getOrCreatePairingCode();
      final codes = [myCode, partnerCode.toUpperCase()]..sort();
      final roomId = codes.join('-');

      // Save pairing info
      await StorageService.instance.setRoomId(roomId);
      await StorageService.instance.setPartnerId(partnerId);

      // Update Firebase with pairing
      final myUserId = StorageService.instance.getUserId();
      if (myUserId != null) {
        await FirebaseDatabase.instance.ref('pairings/$roomId').set({
          'users': [myUserId, partnerId],
          'createdAt': ServerValue.timestamp,
        });
      }

      _partnerId = partnerId;
      _status = PairingStatus.connected;
      _isConnecting = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error joining with code: $e');
      _error = 'Connection failed. Please try again.';
      _status = PairingStatus.error;
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  /// Use my own code to create/join room
  Future<bool> startWithMyCode() async {
    _isConnecting = true;
    _error = null;
    _status = PairingStatus.connecting;
    notifyListeners();

    try {
      final myCode = await getOrCreatePairingCode();

      // Use my code as room ID for now (partner will join with their code)
      await StorageService.instance.setRoomId(myCode);

      _status = PairingStatus.waitingForPartner;
      _isConnecting = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error starting with code: $e');
      _error = 'Failed to create room. Please try again.';
      _status = PairingStatus.error;
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  /// Generate shareable link
  String getShareableLink() {
    final code = _myPairingCode ?? '';
    // For now, return a simple text. Can be upgraded to deep link later
    return 'tether://join/$code';
  }

  /// Share pairing code via system share
  Future<void> shareCode() async {
    final code = _myPairingCode;
    if (code == null) return;

    final message =
        '''💕 Join me on Tether!

My pairing code: $code

Download Tether and enter this code to connect with me!''';

    try {
      await Share.share(message, subject: 'Join me on Tether');
    } catch (e) {
      debugPrint('Error sharing code: $e');
    }
  }

  /// Check if already paired
  Future<bool> checkExistingPairing() async {
    final roomId = StorageService.instance.getRoomId();
    if (roomId != null && roomId.isNotEmpty) {
      _status = PairingStatus.connected;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Disconnect from partner
  Future<void> disconnect() async {
    final roomId = StorageService.instance.getRoomId();

    if (roomId != null) {
      // Optional: Remove pairing from Firebase
      try {
        await FirebaseDatabase.instance.ref('pairings/$roomId').remove();
      } catch (e) {
        debugPrint('Error removing pairing: $e');
      }
    }

    await StorageService.instance.clearRoomId();
    await StorageService.instance.clearPartnerId();

    _partnerId = null;
    _partnerName = null;
    _status = PairingStatus.disconnected;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Pairing connection status
enum PairingStatus {
  disconnected,
  connecting,
  waitingForPartner,
  connected,
  error,
}

extension PairingStatusExtension on PairingStatus {
  String get displayText {
    switch (this) {
      case PairingStatus.disconnected:
        return 'Not connected';
      case PairingStatus.connecting:
        return 'Connecting...';
      case PairingStatus.waitingForPartner:
        return 'Waiting for partner';
      case PairingStatus.connected:
        return 'Connected';
      case PairingStatus.error:
        return 'Connection error';
    }
  }

  bool get isLoading => this == PairingStatus.connecting;
}
