import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available app themes
enum AppThemeType {
  cosmic, // Default purple/pink
  ocean, // Blue/cyan
  sunset, // Orange/red
  forest, // Green/teal
  midnight, // Dark blue/purple
  rose, // Pink/rose
}

extension AppThemeTypeExtension on AppThemeType {
  String get displayName {
    switch (this) {
      case AppThemeType.cosmic:
        return 'Cosmic';
      case AppThemeType.ocean:
        return 'Ocean';
      case AppThemeType.sunset:
        return 'Sunset';
      case AppThemeType.forest:
        return 'Forest';
      case AppThemeType.midnight:
        return 'Midnight';
      case AppThemeType.rose:
        return 'Rose';
    }
  }

  String get emoji {
    switch (this) {
      case AppThemeType.cosmic:
        return '🌌';
      case AppThemeType.ocean:
        return '🌊';
      case AppThemeType.sunset:
        return '🌅';
      case AppThemeType.forest:
        return '🌲';
      case AppThemeType.midnight:
        return '🌙';
      case AppThemeType.rose:
        return '🌹';
    }
  }

  int get primaryColorValue {
    switch (this) {
      case AppThemeType.cosmic:
        return 0xFFE040FB;
      case AppThemeType.ocean:
        return 0xFF00BCD4;
      case AppThemeType.sunset:
        return 0xFFFF5722;
      case AppThemeType.forest:
        return 0xFF4CAF50;
      case AppThemeType.midnight:
        return 0xFF3F51B5;
      case AppThemeType.rose:
        return 0xFFE91E63;
    }
  }

  int get secondaryColorValue {
    switch (this) {
      case AppThemeType.cosmic:
        return 0xFFFF6B6B;
      case AppThemeType.ocean:
        return 0xFF03A9F4;
      case AppThemeType.sunset:
        return 0xFFFF9800;
      case AppThemeType.forest:
        return 0xFF009688;
      case AppThemeType.midnight:
        return 0xFF673AB7;
      case AppThemeType.rose:
        return 0xFFFF4081;
    }
  }

  int get backgroundColorValue {
    switch (this) {
      case AppThemeType.cosmic:
        return 0xFF0D0D1A;
      case AppThemeType.ocean:
        return 0xFF0A1628;
      case AppThemeType.sunset:
        return 0xFF1A0A0A;
      case AppThemeType.forest:
        return 0xFF0A1A0F;
      case AppThemeType.midnight:
        return 0xFF0D0D1F;
      case AppThemeType.rose:
        return 0xFF1A0D14;
    }
  }
}

/// Touch color options
enum TouchColorOption { primary, blue, green, orange, pink, purple, rainbow }

extension TouchColorOptionExtension on TouchColorOption {
  String get displayName {
    switch (this) {
      case TouchColorOption.primary:
        return 'Theme Color';
      case TouchColorOption.blue:
        return 'Ocean Blue';
      case TouchColorOption.green:
        return 'Nature Green';
      case TouchColorOption.orange:
        return 'Warm Orange';
      case TouchColorOption.pink:
        return 'Sweet Pink';
      case TouchColorOption.purple:
        return 'Royal Purple';
      case TouchColorOption.rainbow:
        return 'Rainbow';
    }
  }

  int get colorValue {
    switch (this) {
      case TouchColorOption.primary:
        return 0xFFE040FB;
      case TouchColorOption.blue:
        return 0xFF2196F3;
      case TouchColorOption.green:
        return 0xFF4CAF50;
      case TouchColorOption.orange:
        return 0xFFFF9800;
      case TouchColorOption.pink:
        return 0xFFE91E63;
      case TouchColorOption.purple:
        return 0xFF9C27B0;
      case TouchColorOption.rainbow:
        return 0xFFFFFFFF;
    }
  }
}

/// Service for managing app theme and personalization
class ThemeService extends ChangeNotifier {
  static ThemeService? _instance;
  static ThemeService get instance {
    _instance ??= ThemeService._();
    return _instance!;
  }

  ThemeService._();

  AppThemeType _theme = AppThemeType.cosmic;
  TouchColorOption _touchColor = TouchColorOption.primary;
  bool _showParticles = true;
  bool _hapticFeedback = true;
  bool _soundEffects = false;

  // Getters
  AppThemeType get theme => _theme;
  TouchColorOption get touchColor => _touchColor;
  bool get showParticles => _showParticles;
  bool get hapticFeedback => _hapticFeedback;
  bool get soundEffects => _soundEffects;

  // Color getters
  int get primaryColor => _theme.primaryColorValue;
  int get secondaryColor => _theme.secondaryColorValue;
  int get backgroundColor => _theme.backgroundColorValue;

  int get touchColorValue {
    if (_touchColor == TouchColorOption.primary) {
      return _theme.primaryColorValue;
    }
    return _touchColor.colorValue;
  }

  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final themeName = prefs.getString('theme');
      if (themeName != null) {
        _theme = AppThemeType.values.firstWhere(
          (t) => t.name == themeName,
          orElse: () => AppThemeType.cosmic,
        );
      }

      final touchColorName = prefs.getString('touchColor');
      if (touchColorName != null) {
        _touchColor = TouchColorOption.values.firstWhere(
          (c) => c.name == touchColorName,
          orElse: () => TouchColorOption.primary,
        );
      }

      _showParticles = prefs.getBool('showParticles') ?? true;
      _hapticFeedback = prefs.getBool('hapticFeedback') ?? true;
      _soundEffects = prefs.getBool('soundEffects') ?? false;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme settings: $e');
    }
  }

  Future<void> setTheme(AppThemeType theme) async {
    _theme = theme;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setTouchColor(TouchColorOption color) async {
    _touchColor = color;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setShowParticles(bool value) async {
    _showParticles = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setHapticFeedback(bool value) async {
    _hapticFeedback = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setSoundEffects(bool value) async {
    _soundEffects = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme', _theme.name);
      await prefs.setString('touchColor', _touchColor.name);
      await prefs.setBool('showParticles', _showParticles);
      await prefs.setBool('hapticFeedback', _hapticFeedback);
      await prefs.setBool('soundEffects', _soundEffects);
    } catch (e) {
      debugPrint('Error saving theme settings: $e');
    }
  }
}
