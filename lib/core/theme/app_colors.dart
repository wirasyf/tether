import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient colors - romantic purple/pink
  static const Color primary = Color(0xFFE040FB);
  static const Color primaryLight = Color(0xFFFF79FF);
  static const Color primaryDark = Color(0xFFAA00C7);

  // Secondary - warm coral accent
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color secondaryLight = Color(0xFFFF9E9E);
  static const Color secondaryDark = Color(0xFFC73B3B);

  // Background - deep space dark
  static const Color background = Color(0xFF0D0D1A);
  static const Color backgroundLight = Color(0xFF1A1A2E);

  // Surface - glassmorphism base
  static const Color surface = Color(0xFF16162A);
  // Surface - glassmorphism base
  static const Color surfaceLight = Color(0xFF252542);
  static const Color cardBackground = Color(0xFF1F1F3A);

  // Text colors
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textMuted = Color(0xFF6B6B80);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF29B6F6);

  // Touch effect colors
  static const Color touchRipple = Color(0x40E040FB);
  static const Color touchGlow = Color(0xFFFF79FF);
  static const Color touchParticle = Color(0xFFFFD54F);

  // Gesture specific colors
  static const Color loveRed = Color(0xFFFF1744);
  static const Color highFiveGold = Color(0xFFFFD700);
  static const Color calmBlue = Color(0xFF64B5F6);
  static const Color pinchOrange = Color(0xFFFF9800);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, backgroundLight, Color(0xFF1F1F3A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x20FFFFFF), Color(0x08FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient touchGlowGradient = RadialGradient(
    colors: [Color(0x60E040FB), Color(0x30E040FB), Color(0x00E040FB)],
    stops: [0.0, 0.5, 1.0],
  );
}
