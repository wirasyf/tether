import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/visual_themes.dart';

/// Settings service to manage user preferences
class SettingsService extends ChangeNotifier {
  static SettingsService? _instance;
  SharedPreferences? _prefs;
  
  // Settings keys
  static const String _keyVisualTheme = 'visual_theme';
  static const String _keyHapticsEnabled = 'haptics_enabled';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyGhostTouchEnabled = 'ghost_touch_enabled';
  static const String _keyPartnerName = 'partner_name';
  
  // Default values
  VisualTheme _visualTheme = VisualTheme.romantic;
  bool _hapticsEnabled = true;
  bool _soundEnabled = true;
  bool _notificationsEnabled = true;
  bool _ghostTouchEnabled = true;
  String _partnerName = 'Partner';
  
  SettingsService._();
  
  static SettingsService get instance {
    _instance ??= SettingsService._();
    return _instance!;
  }
  
  // Getters
  VisualTheme get visualTheme => _visualTheme;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get ghostTouchEnabled => _ghostTouchEnabled;
  String get partnerName => _partnerName;
  
  /// Initialize settings from storage
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }
  
  void _loadSettings() {
    final themeIndex = _prefs?.getInt(_keyVisualTheme) ?? 0;
    _visualTheme = VisualTheme.values[themeIndex.clamp(0, VisualTheme.values.length - 1)];
    _hapticsEnabled = _prefs?.getBool(_keyHapticsEnabled) ?? true;
    _soundEnabled = _prefs?.getBool(_keySoundEnabled) ?? true;
    _notificationsEnabled = _prefs?.getBool(_keyNotificationsEnabled) ?? true;
    _ghostTouchEnabled = _prefs?.getBool(_keyGhostTouchEnabled) ?? true;
    _partnerName = _prefs?.getString(_keyPartnerName) ?? 'Partner';
    notifyListeners();
  }
  
  /// Set visual theme
  Future<void> setVisualTheme(VisualTheme theme) async {
    _visualTheme = theme;
    await _prefs?.setInt(_keyVisualTheme, theme.index);
    notifyListeners();
  }
  
  /// Toggle haptics
  Future<void> setHapticsEnabled(bool enabled) async {
    _hapticsEnabled = enabled;
    await _prefs?.setBool(_keyHapticsEnabled, enabled);
    notifyListeners();
  }
  
  /// Toggle sound
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _prefs?.setBool(_keySoundEnabled, enabled);
    notifyListeners();
  }
  
  /// Toggle notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _prefs?.setBool(_keyNotificationsEnabled, enabled);
    notifyListeners();
  }
  
  /// Toggle ghost touch
  Future<void> setGhostTouchEnabled(bool enabled) async {
    _ghostTouchEnabled = enabled;
    await _prefs?.setBool(_keyGhostTouchEnabled, enabled);
    notifyListeners();
  }
  
  /// Set partner name
  Future<void> setPartnerName(String name) async {
    _partnerName = name;
    await _prefs?.setString(_keyPartnerName, name);
    notifyListeners();
  }
  
  /// Get current theme colors
  ThemeColors get currentThemeColors => VisualThemeData.getTheme(_visualTheme);
}
