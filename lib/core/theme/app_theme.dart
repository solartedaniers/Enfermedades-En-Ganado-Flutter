import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color accent;
  final Color appBarDark;
  final Color cardDark;
  final Color inputBorderLight;
  final Color inputBorderDark;
  final Color selectionBackground;
  final Color chipForeground;
  final Color medicalHeaderStart;
  final Color medicalHeaderEnd;

  const AppThemeColors({
    required this.accent,
    required this.appBarDark,
    required this.cardDark,
    required this.inputBorderLight,
    required this.inputBorderDark,
    required this.selectionBackground,
    required this.chipForeground,
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
    Color? selectionBackground,
    Color? chipForeground,
    Color? medicalHeaderStart,
    Color? medicalHeaderEnd,
  }) {
    return AppThemeColors(
      accent: accent ?? this.accent,
      appBarDark: appBarDark ?? this.appBarDark,
      cardDark: cardDark ?? this.cardDark,
      inputBorderLight: inputBorderLight ?? this.inputBorderLight,
      inputBorderDark: inputBorderDark ?? this.inputBorderDark,
      selectionBackground: selectionBackground ?? this.selectionBackground,
      chipForeground: chipForeground ?? this.chipForeground,
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
      selectionBackground:
          Color.lerp(selectionBackground, other.selectionBackground, t) ??
              selectionBackground,
      chipForeground:
          Color.lerp(chipForeground, other.chipForeground, t) ?? chipForeground,
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
    selectionBackground: Color(0xFFE8F5E9),
    chipForeground: primaryColor,
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
      fillColor: const Color(0xFF2A2A2A),
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
