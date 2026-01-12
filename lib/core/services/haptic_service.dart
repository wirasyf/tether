import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Haptic feedback service for touch-based communication
/// Provides various vibration patterns for different gestures
class HapticService {
  static HapticService? _instance;
  bool _hasVibrator = false;
  bool _hasAmplitudeControl = false;
  bool _isSupported = false;
  
  HapticService._();
  
  static HapticService get instance {
    _instance ??= HapticService._();
    return _instance!;
  }
  
  /// Initialize haptic capabilities
  Future<void> initialize() async {
    // Vibration only works on mobile platforms
    if (kIsWeb) {
      _isSupported = false;
      _hasVibrator = false;
      return;
    }
    
    try {
      _hasVibrator = await Vibration.hasVibrator() ?? false;
      _hasAmplitudeControl = await Vibration.hasAmplitudeControl() ?? false;
      _isSupported = _hasVibrator;
    } catch (e) {
      // Platform doesn't support vibration
      _isSupported = false;
      _hasVibrator = false;
    }
  }
  
  bool get isAvailable => _hasVibrator && _isSupported;
  bool get hasAmplitudeControl => _hasAmplitudeControl;
  
  /// Light tap feedback
  Future<void> lightTap() async {
    if (!isAvailable) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }
  
  /// Medium tap feedback
  Future<void> mediumTap() async {
    if (!isAvailable) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }
  
  /// Heavy tap feedback
  Future<void> heavyTap() async {
    if (!isAvailable) return;
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }
  
  /// Single short vibration for tap
  Future<void> tap() async {
    if (!isAvailable) return;
    try {
      await Vibration.vibrate(duration: 50, amplitude: 128);
    } catch (_) {}
  }
  
  /// Pulsing vibration for long press
  Future<void> longPressStart() async {
    if (!isAvailable) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 100, 100, 100, 100, 100, 100, 100],
        intensities: [0, 180, 0, 180, 0, 180, 0, 180],
      );
    } catch (_) {}
  }
  
  /// Stop all vibrations
  Future<void> stop() async {
    if (!_isSupported) return;
    try {
      await Vibration.cancel();
    } catch (_) {}
  }
  
  /// Double tap - Love gesture
  Future<void> doubleTapLove() async {
    if (!isAvailable) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 100, 80, 100],
        intensities: [0, 255, 0, 255],
      );
    } catch (_) {}
  }
  
  /// Swipe up - High Five
  Future<void> swipeUpHighFive() async {
    if (!isAvailable) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 50, 30, 70, 30, 90, 30, 110],
        intensities: [0, 100, 0, 150, 0, 200, 0, 255],
      );
    } catch (_) {}
  }
  
  /// Circle motion - Calming pattern
  Future<void> circleCalm() async {
    if (!isAvailable) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 80, 120, 80, 120, 80, 120, 80, 120, 80],
        intensities: [0, 100, 0, 130, 0, 160, 0, 130, 0, 100],
      );
    } catch (_) {}
  }
  
  /// Two finger pinch - Sharp buzz
  Future<void> pinchSharp() async {
    if (!isAvailable) return;
    try {
      await Vibration.vibrate(duration: 80, amplitude: 255);
    } catch (_) {}
  }
  
  /// Ghost touch notification
  Future<void> ghostTouchNotify() async {
    if (!isAvailable) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 50, 100, 50, 100, 100],
        intensities: [0, 150, 0, 150, 0, 200],
      );
    } catch (_) {}
  }
  
  /// Continuous touch - for tracking finger movement
  Future<void> touchMove() async {
    if (!isAvailable) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }
  
  /// Partner connected notification
  Future<void> partnerConnected() async {
    if (!isAvailable) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 100, 100, 200],
        intensities: [0, 180, 0, 255],
      );
    } catch (_) {}
  }
  
  /// Partner disconnected notification
  Future<void> partnerDisconnected() async {
    if (!isAvailable) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 200, 150, 200],
        intensities: [0, 150, 0, 100],
      );
    } catch (_) {}
  }
  
  // ============ Premium Haptic Patterns ============
  
  /// Heartbeat - rhythmic loving pattern
  Future<void> heartbeat() async {
    if (!isAvailable) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 80, 100, 120, 500, 80, 100, 120],
        intensities: [0, 200, 0, 255, 0, 200, 0, 255],
      );
    } catch (_) {}
  }
  
  /// Butterfly - gentle fluttering pattern
  Future<void> butterfly() async {
    if (!isAvailable) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 30, 50, 30, 50, 30, 50, 30, 50, 30, 50, 30],
        intensities: [0, 100, 0, 120, 0, 140, 0, 120, 0, 100, 0, 80],
      );
    } catch (_) {}
  }
  
  /// Wave - ocean-like rolling pattern
  Future<void> wave() async {
    if (!isAvailable) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 100, 50, 150, 50, 200, 50, 150, 50, 100],
        intensities: [0, 80, 0, 120, 0, 180, 0, 120, 0, 80],
      );
    } catch (_) {}
  }
  
  /// Sparkle - celebratory bursts
  Future<void> sparkle() async {
    if (!isAvailable) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 40, 80, 40, 80, 40, 80, 40, 80, 60],
        intensities: [0, 255, 0, 200, 0, 255, 0, 180, 0, 255],
      );
    } catch (_) {}
  }
  
  /// Warm hug - sustained gentle vibration
  Future<void> warmHug() async {
    if (!isAvailable) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 300, 100, 400, 100, 300],
        intensities: [0, 100, 0, 130, 0, 100],
      );
    } catch (_) {}
  }
  
  /// Thinking of you - gentle reminder
  Future<void> thinkingOfYou() async {
    if (!isAvailable) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 60, 200, 60, 200, 60],
        intensities: [0, 150, 0, 180, 0, 150],
      );
    } catch (_) {}
  }
}
