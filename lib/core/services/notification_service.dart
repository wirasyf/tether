import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';

/// Service for managing push notifications via FCM
class NotificationService extends ChangeNotifier {
  static NotificationService? _instance;
  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;
  String? _roomId;
  String? _myId;

  String? get fcmToken => _fcmToken;

  /// Initialize notification service
  Future<void> initialize({
    required String roomId,
    required String myId,
  }) async {
    _roomId = roomId;
    _myId = myId;

    // Request permission (especially for iOS)
    await _requestPermission();

    // Get FCM token
    await _getToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('Notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  Future<void> _getToken() async {
    try {
      // For web, need to provide VAPID key
      if (kIsWeb) {
        // Note: VAPID key should be configured in Firebase Console
        _fcmToken = await _messaging.getToken(
          vapidKey: null, // Add your VAPID key if needed
        );
      } else {
        _fcmToken = await _messaging.getToken();
      }

      if (_fcmToken != null) {
        debugPrint('FCM Token: $_fcmToken');
        await _saveTokenToDatabase();
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  void _onTokenRefresh(String token) {
    _fcmToken = token;
    _saveTokenToDatabase();
    notifyListeners();
  }

  Future<void> _saveTokenToDatabase() async {
    if (_roomId == null || _myId == null || _fcmToken == null) return;

    try {
      await FirebaseDatabase.instance
          .ref('rooms/$_roomId/fcmTokens/$_myId')
          .set({'token': _fcmToken, 'updatedAt': ServerValue.timestamp});
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    // Handle foreground notification - could show a local notification or overlay
    notifyListeners();
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.notification?.title}');
    // Navigate to relevant screen based on message data
  }

  /// Send notification to partner
  /// Note: This typically requires a backend/Cloud Functions to send FCM messages
  Future<void> notifyPartner({
    required String title,
    required String body,
    String? type,
  }) async {
    if (_roomId == null || _myId == null) return;

    try {
      // Store notification request in Firebase
      // A Cloud Function should listen to this and send the actual FCM message
      await FirebaseDatabase.instance
          .ref('rooms/$_roomId/notifications')
          .push()
          .set({
            'senderId': _myId,
            'title': title,
            'body': body,
            'type': type ?? 'general',
            'timestamp': ServerValue.timestamp,
            'sent': false,
          });
    } catch (e) {
      debugPrint('Error notifying partner: $e');
    }
  }

  void dispose() {
    super.dispose();
  }
}
