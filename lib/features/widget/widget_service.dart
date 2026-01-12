import 'package:home_widget/home_widget.dart';
import '../../models/touch_event.dart';
import '../../models/gesture_type.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/haptic_service.dart';

/// Service to manage home screen widget functionality
class WidgetService {
  static WidgetService? _instance;
  static const String _appGroupId = 'group.com.tether.widget';
  static const String _androidWidgetName = 'TetherWidgetProvider';
  
  // Widget data keys
  static const String _keyPartnerOnline = 'partner_online';
  static const String _keyLastTouch = 'last_touch';
  static const String _keyPendingTouches = 'pending_touches';
  
  WidgetService._();
  
  static WidgetService get instance {
    _instance ??= WidgetService._();
    return _instance!;
  }
  
  /// Initialize widget service
  Future<void> initialize() async {
    // Set app group for data sharing
    await HomeWidget.setAppGroupId(_appGroupId);
    
    // Register callback for widget interactions
    HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);
  }
  
  /// Update widget with current status
  Future<void> updateWidget({
    required bool isPartnerOnline,
    int pendingTouches = 0,
    String? lastTouchTime,
  }) async {
    await HomeWidget.saveWidgetData(_keyPartnerOnline, isPartnerOnline);
    await HomeWidget.saveWidgetData(_keyPendingTouches, pendingTouches);
    if (lastTouchTime != null) {
      await HomeWidget.saveWidgetData(_keyLastTouch, lastTouchTime);
    }
    
    // Request widget update
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
    );
  }
  
  /// Send quick touch from widget
  Future<void> sendQuickTouch() async {
    // Create a centered tap
    final touch = TouchEvent.create(
      x: 0.5,
      y: 0.5,
      type: TouchType.tap,
    );
    
    // Trigger haptic feedback
    await HapticService.instance.tap();
    
    // Send via socket
    SocketService.instance.sendTouch(touch);
  }
  
  /// Send quick love gesture from widget
  Future<void> sendQuickLove() async {
    final gesture = GestureEvent.create(
      type: GestureType.doubleTap,
      x: 0.5,
      y: 0.5,
    );
    
    // Trigger haptic
    await HapticService.instance.doubleTapLove();
    
    // Send
    SocketService.instance.sendGesture(gesture);
  }
  
  /// Handle widget interaction in background
  static Future<void> widgetBackgroundCallback(Uri? uri) async {
    if (uri == null) return;
    
    final action = uri.host;
    
    switch (action) {
      case 'tap':
        await WidgetService.instance.sendQuickTouch();
        break;
      case 'love':
        await WidgetService.instance.sendQuickLove();
        break;
      case 'open':
        // Open app - handled by system
        break;
    }
  }
}
