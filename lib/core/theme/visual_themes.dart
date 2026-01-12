import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Visual theme definitions for Tether app
/// Each theme provides different visual effects and color palettes

enum VisualTheme {
  romantic,   // Default - purples and pinks
  sakura,     // Cherry blossom - soft pinks
  ocean,      // Ocean waves - blues and teals
  sunset,     // Warm sunset - oranges and yellows
  aurora,     // Northern lights - greens and purples
  midnight,   // Deep night - dark blues
}

class ThemeColors {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Gradient touchGradient;
  final Gradient backgroundGradient;
  final List<Color> particleColors;
  
  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.touchGradient,
    required this.backgroundGradient,
    required this.particleColors,
  });
}

class VisualThemeData {
  static ThemeColors getTheme(VisualTheme theme) {
    switch (theme) {
      case VisualTheme.romantic:
        return _romanticTheme;
      case VisualTheme.sakura:
        return _sakuraTheme;
      case VisualTheme.ocean:
        return _oceanTheme;
      case VisualTheme.sunset:
        return _sunsetTheme;
      case VisualTheme.aurora:
        return _auroraTheme;
      case VisualTheme.midnight:
        return _midnightTheme;
    }
  }
  
  // Default romantic theme
  static const ThemeColors _romanticTheme = ThemeColors(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    accent: Color(0xFFF472B6),
    background: AppColors.background,
    surface: AppColors.surface,
    touchGradient: LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0D0D1A), Color(0xFF1A0A20), Color(0xFF0D0D1A)],
    ),
    particleColors: [Color(0xFFEC4899), Color(0xFF8B5CF6), Color(0xFFF472B6)],
  );
  
  // Sakura (cherry blossom) theme
  static const ThemeColors _sakuraTheme = ThemeColors(
    primary: Color(0xFFFFB7C5),
    secondary: Color(0xFFF8C8DC),
    accent: Color(0xFFFF69B4),
    background: Color(0xFF1A0F14),
    surface: Color(0xFF2A1F24),
    touchGradient: LinearGradient(
      colors: [Color(0xFFFFB7C5), Color(0xFFFF69B4)],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A0F14), Color(0xFF2A1A20), Color(0xFF1A0F14)],
    ),
    particleColors: [Color(0xFFFFB7C5), Color(0xFFF8C8DC), Color(0xFFFFFFFF)],
  );
  
  // Ocean theme
  static const ThemeColors _oceanTheme = ThemeColors(
    primary: Color(0xFF06B6D4),
    secondary: Color(0xFF0EA5E9),
    accent: Color(0xFF22D3EE),
    background: Color(0xFF0A1628),
    surface: Color(0xFF1A2638),
    touchGradient: LinearGradient(
      colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0A1628), Color(0xFF0D2847), Color(0xFF0A1628)],
    ),
    particleColors: [Color(0xFF06B6D4), Color(0xFF22D3EE), Color(0xFFFFFFFF)],
  );
  
  // Sunset theme
  static const ThemeColors _sunsetTheme = ThemeColors(
    primary: Color(0xFFF97316),
    secondary: Color(0xFFFB923C),
    accent: Color(0xFFEAB308),
    background: Color(0xFF1A0F0A),
    surface: Color(0xFF2A1F1A),
    touchGradient: LinearGradient(
      colors: [Color(0xFFF97316), Color(0xFFEAB308)],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1A0F0A), Color(0xFF2A1510), Color(0xFF1A0A0A)],
    ),
    particleColors: [Color(0xFFF97316), Color(0xFFFB923C), Color(0xFFEAB308)],
  );
  
  // Aurora theme
  static const ThemeColors _auroraTheme = ThemeColors(
    primary: Color(0xFF10B981),
    secondary: Color(0xFF8B5CF6),
    accent: Color(0xFF06B6D4),
    background: Color(0xFF0A1A14),
    surface: Color(0xFF1A2A24),
    touchGradient: LinearGradient(
      colors: [Color(0xFF10B981), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0A1A14), Color(0xFF0A1428), Color(0xFF0A1A14)],
    ),
    particleColors: [Color(0xFF10B981), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
  );
  
  // Midnight theme
  static const ThemeColors _midnightTheme = ThemeColors(
    primary: Color(0xFF6366F1),
    secondary: Color(0xFF4F46E5),
    accent: Color(0xFF818CF8),
    background: Color(0xFF030712),
    surface: Color(0xFF111827),
    touchGradient: LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF030712), Color(0xFF0F172A), Color(0xFF030712)],
    ),
    particleColors: [Color(0xFF6366F1), Color(0xFF818CF8), Color(0xFFFFFFFF)],
  );
}
