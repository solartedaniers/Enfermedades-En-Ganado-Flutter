import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color accent;
  final Color appBarDark;
  final Color cardDark;
  final Color inputBorderLight;
  final Color inputBorderDark;
  final Color authBackgroundLight;
  final Color authBackgroundDark;
  final Color inputFillDark;
  final Color selectionBackground;
  final Color chipForeground;
  final Color mutedForeground;
  final Color subduedForeground;
  final Color whiteOverlay;
  final Color danger;
  final Color warning;
  final Color success;
  final Color heroGradientStart;
  final Color heroGradientEnd;
  final Color scannerAccent;
  final Color scannerBackground;
  final Color scannerTarget;
  final Color cameraOverlay;
  final Color medicalHeaderStart;
  final Color medicalHeaderEnd;

  const AppThemeColors({
    required this.accent,
    required this.appBarDark,
    required this.cardDark,
    required this.inputBorderLight,
    required this.inputBorderDark,
    required this.authBackgroundLight,
    required this.authBackgroundDark,
    required this.inputFillDark,
    required this.selectionBackground,
    required this.chipForeground,
    required this.mutedForeground,
    required this.subduedForeground,
    required this.whiteOverlay,
    required this.danger,
    required this.warning,
    required this.success,
    required this.heroGradientStart,
    required this.heroGradientEnd,
    required this.scannerAccent,
    required this.scannerBackground,
    required this.scannerTarget,
    required this.cameraOverlay,
    required this.medicalHeaderStart,
    required this.medicalHeaderEnd,
  });

  @override
  AppThemeColors copyWith({
    Color? accent,
    Color? appBarDark,
    Color? cardDark,
    Color? inputBorderLight,
    Color? inputBorderDark,
    Color? authBackgroundLight,
    Color? authBackgroundDark,
    Color? inputFillDark,
    Color? selectionBackground,
    Color? chipForeground,
    Color? mutedForeground,
    Color? subduedForeground,
    Color? whiteOverlay,
    Color? danger,
    Color? warning,
    Color? success,
    Color? heroGradientStart,
    Color? heroGradientEnd,
    Color? scannerAccent,
    Color? scannerBackground,
    Color? scannerTarget,
    Color? cameraOverlay,
    Color? medicalHeaderStart,
    Color? medicalHeaderEnd,
  }) {
    return AppThemeColors(
      accent: accent ?? this.accent,
      appBarDark: appBarDark ?? this.appBarDark,
      cardDark: cardDark ?? this.cardDark,
      inputBorderLight: inputBorderLight ?? this.inputBorderLight,
      inputBorderDark: inputBorderDark ?? this.inputBorderDark,
      authBackgroundLight: authBackgroundLight ?? this.authBackgroundLight,
      authBackgroundDark: authBackgroundDark ?? this.authBackgroundDark,
      inputFillDark: inputFillDark ?? this.inputFillDark,
      selectionBackground: selectionBackground ?? this.selectionBackground,
      chipForeground: chipForeground ?? this.chipForeground,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      subduedForeground: subduedForeground ?? this.subduedForeground,
      whiteOverlay: whiteOverlay ?? this.whiteOverlay,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      success: success ?? this.success,
      heroGradientStart: heroGradientStart ?? this.heroGradientStart,
      heroGradientEnd: heroGradientEnd ?? this.heroGradientEnd,
      scannerAccent: scannerAccent ?? this.scannerAccent,
      scannerBackground: scannerBackground ?? this.scannerBackground,
      scannerTarget: scannerTarget ?? this.scannerTarget,
      cameraOverlay: cameraOverlay ?? this.cameraOverlay,
      medicalHeaderStart: medicalHeaderStart ?? this.medicalHeaderStart,
      medicalHeaderEnd: medicalHeaderEnd ?? this.medicalHeaderEnd,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }

    return AppThemeColors(
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      appBarDark: Color.lerp(appBarDark, other.appBarDark, t) ?? appBarDark,
      cardDark: Color.lerp(cardDark, other.cardDark, t) ?? cardDark,
      inputBorderLight: Color.lerp(inputBorderLight, other.inputBorderLight, t) ??
          inputBorderLight,
      inputBorderDark:
          Color.lerp(inputBorderDark, other.inputBorderDark, t) ?? inputBorderDark,
      authBackgroundLight:
          Color.lerp(authBackgroundLight, other.authBackgroundLight, t) ??
              authBackgroundLight,
      authBackgroundDark:
          Color.lerp(authBackgroundDark, other.authBackgroundDark, t) ??
              authBackgroundDark,
      inputFillDark: Color.lerp(inputFillDark, other.inputFillDark, t) ?? inputFillDark,
      selectionBackground:
          Color.lerp(selectionBackground, other.selectionBackground, t) ??
              selectionBackground,
      chipForeground:
          Color.lerp(chipForeground, other.chipForeground, t) ?? chipForeground,
      mutedForeground:
          Color.lerp(mutedForeground, other.mutedForeground, t) ?? mutedForeground,
      subduedForeground:
          Color.lerp(subduedForeground, other.subduedForeground, t) ??
              subduedForeground,
      whiteOverlay: Color.lerp(whiteOverlay, other.whiteOverlay, t) ?? whiteOverlay,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      success: Color.lerp(success, other.success, t) ?? success,
      heroGradientStart:
          Color.lerp(heroGradientStart, other.heroGradientStart, t) ??
              heroGradientStart,
      heroGradientEnd:
          Color.lerp(heroGradientEnd, other.heroGradientEnd, t) ?? heroGradientEnd,
      scannerAccent:
          Color.lerp(scannerAccent, other.scannerAccent, t) ?? scannerAccent,
      scannerBackground:
          Color.lerp(scannerBackground, other.scannerBackground, t) ??
              scannerBackground,
      scannerTarget:
          Color.lerp(scannerTarget, other.scannerTarget, t) ?? scannerTarget,
      cameraOverlay:
          Color.lerp(cameraOverlay, other.cameraOverlay, t) ?? cameraOverlay,
      medicalHeaderStart:
          Color.lerp(medicalHeaderStart, other.medicalHeaderStart, t) ??
              medicalHeaderStart,
      medicalHeaderEnd:
          Color.lerp(medicalHeaderEnd, other.medicalHeaderEnd, t) ??
              medicalHeaderEnd,
    );
  }
}

class AppTheme {
  static const primaryColor = Color(0xFF2E7D32);
  static const accentColor = Color(0xFF66BB6A);

  static const _themeColors = AppThemeColors(
    accent: accentColor,
    appBarDark: Color(0xFF1B5E20),
    cardDark: Color(0xFF1E1E1E),
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
    scannerAccent: Color(0xFFBF22DF),
    scannerBackground: Color(0xFFF8F5FC),
    scannerTarget: Color(0xFF34C759),
    cameraOverlay: Color(0x8C000000),
    medicalHeaderStart: primaryColor,
    medicalHeaderEnd: accentColor,
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F6FA),
    extensions: const [ _themeColors ],
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: primaryColor.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          letterSpacing: 0.5,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 6,
    ),
    listTileTheme: const ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    extensions: const [ _themeColors ],
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: _themeColors.appBarDark,
      foregroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      color: _themeColors.cardDark,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _themeColors.inputFillDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: primaryColor.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          letterSpacing: 0.5,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 6,
    ),
  );
}

extension AppThemeColorsX on BuildContext {
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>()!;
}
