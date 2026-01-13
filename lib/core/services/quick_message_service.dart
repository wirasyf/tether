import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

/// Preset quick messages
enum QuickMessage {
  missYou,
  loveYou,
  thinkingOfYou,
  goodMorning,
  goodNight,
  hugYou,
  beRightBack,
  youreAmazing,
}

extension QuickMessageExtension on QuickMessage {
  String get text {
    switch (this) {
      case QuickMessage.missYou:
        return 'Miss you 💕';
      case QuickMessage.loveYou:
        return 'Love you ❤️';
      case QuickMessage.thinkingOfYou:
        return 'Thinking of you 💭';
      case QuickMessage.goodMorning:
        return 'Good morning ☀️';
      case QuickMessage.goodNight:
        return 'Good night 🌙';
      case QuickMessage.hugYou:
        return 'Sending hugs 🤗';
      case QuickMessage.beRightBack:
        return 'Be right back ⏳';
      case QuickMessage.youreAmazing:
        return 'You\'re amazing ⭐';
    }
  }

  String get emoji {
    switch (this) {
      case QuickMessage.missYou:
        return '💕';
      case QuickMessage.loveYou:
        return '❤️';
      case QuickMessage.thinkingOfYou:
        return '💭';
      case QuickMessage.goodMorning:
        return '☀️';
      case QuickMessage.goodNight:
        return '🌙';
      case QuickMessage.hugYou:
        return '🤗';
      case QuickMessage.beRightBack:
        return '⏳';
      case QuickMessage.youreAmazing:
        return '⭐';
    }
  }
}

/// Incoming message event - supports both preset and custom messages
class MessageEvent {
  final QuickMessage? presetMessage;
  final String? customText;
  final DateTime timestamp;
  final bool isFromPartner;

  MessageEvent({
    this.presetMessage,
    this.customText,
    required this.timestamp,
    this.isFromPartner = false,
  });

  /// Factory for preset message
  MessageEvent.preset({
    required QuickMessage message,
    required this.timestamp,
    this.isFromPartner = false,
  }) : presetMessage = message,
       customText = null;

  /// Factory for custom message
  MessageEvent.custom({
    required String text,
    required this.timestamp,
    this.isFromPartner = false,
  }) : presetMessage = null,
       customText = text;

  /// Get display text
  String get displayText {
    if (customText != null) return customText!;
    return presetMessage?.text ?? '';
  }

  /// Get emoji (💬 for custom messages)
  String get emoji {
    if (customText != null) return '💬';
    return presetMessage?.emoji ?? '💬';
  }

  /// Check if this is a custom message
  bool get isCustom => customText != null;
}

/// Service for quick messages
class QuickMessageService extends ChangeNotifier {
  static QuickMessageService? _instance;
  static QuickMessageService get instance {
    _instance ??= QuickMessageService._();
    return _instance!;
  }

  QuickMessageService._();

  String? _roomId;
  String? _myId;
  StreamSubscription? _messageSubscription;

  final StreamController<MessageEvent> _messageController =
      StreamController<MessageEvent>.broadcast();
  Stream<MessageEvent> get incomingMessages => _messageController.stream;

  MessageEvent? _latestMessage;
  MessageEvent? get latestMessage => _latestMessage;

  Future<void> initialize({
    required String roomId,
    required String myId,
  }) async {
    _roomId = roomId;
    _myId = myId;

    _messageSubscription = FirebaseDatabase.instance
        .ref('rooms/$roomId/messages')
        .onChildAdded
        .listen(_handleIncomingMessage);
  }

  void _handleIncomingMessage(DatabaseEvent event) {
    try {
      final snapshotValue = event.snapshot.value;
      if (snapshotValue == null) return;

      Map<String, dynamic> data;
      if (snapshotValue is Map) {
        data = Map<String, dynamic>.from(snapshotValue);
      } else {
        return;
      }

      // Ignore my own messages
      if (data['senderId'] == _myId) return;

      final customText = data['customText']?.toString();
      final messageName = data['message']?.toString();

      if (customText != null) {
        // Custom message
        _latestMessage = MessageEvent.custom(
          text: customText,
          timestamp: DateTime.now(),
          isFromPartner: true,
        );
      } else if (messageName != null) {
        // Preset message
        final message = QuickMessage.values.firstWhere(
          (m) => m.name == messageName,
          orElse: () => QuickMessage.loveYou,
        );
        _latestMessage = MessageEvent.preset(
          message: message,
          timestamp: DateTime.now(),
          isFromPartner: true,
        );
      } else {
        return;
      }

      _messageController.add(_latestMessage!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing incoming message: $e');
    }
  }

  /// Send a quick message
  Future<void> sendMessage(QuickMessage message) async {
    if (_roomId == null || _myId == null) return;

    try {
      await FirebaseDatabase.instance.ref('rooms/$_roomId/messages').push().set(
        {
          'message': message.name,
          'senderId': _myId,
          'timestamp': ServerValue.timestamp,
        },
      );

      _latestMessage = MessageEvent.preset(
        message: message,
        timestamp: DateTime.now(),
        isFromPartner: false,
      );
      notifyListeners();

      _cleanupOldMessages();
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  /// Send a custom text message
  Future<void> sendCustomMessage(String text) async {
    if (_roomId == null || _myId == null) return;
    if (text.trim().isEmpty) return;

    try {
      await FirebaseDatabase.instance
          .ref('rooms/$_roomId/messages')
          .push()
          .set({
            'customText': text.trim(),
            'senderId': _myId,
            'timestamp': ServerValue.timestamp,
          });

      _latestMessage = MessageEvent.custom(
        text: text.trim(),
        timestamp: DateTime.now(),
        isFromPartner: false,
      );
      notifyListeners();

      _cleanupOldMessages();
    } catch (e) {
      debugPrint('Error sending custom message: $e');
    }
  }

  Future<void> _cleanupOldMessages() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('rooms/$_roomId/messages')
          .orderByChild('timestamp')
          .limitToFirst(1)
          .get();

      if (snapshot.exists && snapshot.children.length > 20) {
        for (final child in snapshot.children.take(5)) {
          await child.ref.remove();
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  void clearLatestMessage() {
    _latestMessage = null;
    notifyListeners();
  }

  void dispose() {
    _messageSubscription?.cancel();
    _messageController.close();
    super.dispose();
  }
}
