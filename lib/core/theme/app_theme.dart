import 'package:flutter/material.dart';

import 'app_theme_colors.dart';
import 'app_theme_factory.dart';

export 'app_theme_colors.dart';

class AppTheme {
  static const primaryColor = Color(0xFF2E7D32);
  static const accentColor = Color(0xFF66BB6A);
  static const onSolidColor = Colors.white;

  static const themeColors = AppThemeColors(
    accent: accentColor,
    onSolid: onSolidColor,
    appBarDark: Color(0xFF1B5E20),
    cardDark: Color(0xFF1E1E1E),
    scaffoldBackgroundLight: Color(0xFFF5F6FA),
    inputBorderLight: Color(0xFFDEE2E6),
    inputBorderDark: Color(0xFF3A3A3A),
    authBackgroundLight: Color(0xFFF1F8F5),
    authBackgroundDark: Color(0xFF121212),
    inputFillDark: Color(0xFF2A2A2A),
    selectionBackground: Color(0xFFE8F5E9),
    chipForeground: primaryColor,
    mutedForeground: Color(0xFF757575),
    subduedForeground: Color(0xFF616161),
    whiteOverlay: Color(0x3DFFFFFF),
    danger: Color(0xFFE53935),
    warning: Color(0xFFF57C00),
    success: Color(0xFF43A047),
    heroGradientStart: Color(0xFF1B5E20),
    heroGradientEnd: Color(0xFF43A047),
    scannerAccent: primaryColor,
    scannerBackground: Color(0xFFF4FAF5),
    scannerTarget: Color(0xFF34C759),
    cameraOverlay: Color(0x8C000000),
    medicalHeaderStart: primaryColor,
    medicalHeaderEnd: accentColor,
    lightShadow: Color(0x1F000000),
    darkShadow: Color(0x61000000),
  );

  static final AppThemeFactory _factory = AppThemeFactory(themeColors);

  static ThemeData lightTheme = _factory.buildLightTheme(
    primaryColor: primaryColor,
  );

  static ThemeData darkTheme = _factory.buildDarkTheme(
    primaryColor: primaryColor,
    accentColor: accentColor,
  );
}
