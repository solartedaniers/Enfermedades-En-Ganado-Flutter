import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color accent;
  final Color onSolid;
  final Color appBarDark;
  final Color cardDark;
  final Color scaffoldBackgroundLight;
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
  final Color lightShadow;
  final Color darkShadow;

  const AppThemeColors({
    required this.accent,
    required this.onSolid,
    required this.appBarDark,
    required this.cardDark,
    required this.scaffoldBackgroundLight,
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
    required this.lightShadow,
    required this.darkShadow,
  });

  @override
  AppThemeColors copyWith({
    Color? accent,
    Color? onSolid,
    Color? appBarDark,
    Color? cardDark,
    Color? scaffoldBackgroundLight,
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
    Color? lightShadow,
    Color? darkShadow,
  }) {
    return AppThemeColors(
      accent: accent ?? this.accent,
      onSolid: onSolid ?? this.onSolid,
      appBarDark: appBarDark ?? this.appBarDark,
      cardDark: cardDark ?? this.cardDark,
      scaffoldBackgroundLight:
          scaffoldBackgroundLight ?? this.scaffoldBackgroundLight,
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
      lightShadow: lightShadow ?? this.lightShadow,
      darkShadow: darkShadow ?? this.darkShadow,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }

    return AppThemeColors(
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      onSolid: Color.lerp(onSolid, other.onSolid, t) ?? onSolid,
      appBarDark: Color.lerp(appBarDark, other.appBarDark, t) ?? appBarDark,
      cardDark: Color.lerp(cardDark, other.cardDark, t) ?? cardDark,
      scaffoldBackgroundLight:
          Color.lerp(
            scaffoldBackgroundLight,
            other.scaffoldBackgroundLight,
            t,
          ) ??
          scaffoldBackgroundLight,
      inputBorderLight:
          Color.lerp(inputBorderLight, other.inputBorderLight, t) ??
              inputBorderLight,
      inputBorderDark:
          Color.lerp(inputBorderDark, other.inputBorderDark, t) ??
              inputBorderDark,
      authBackgroundLight:
          Color.lerp(authBackgroundLight, other.authBackgroundLight, t) ??
              authBackgroundLight,
      authBackgroundDark:
          Color.lerp(authBackgroundDark, other.authBackgroundDark, t) ??
              authBackgroundDark,
      inputFillDark:
          Color.lerp(inputFillDark, other.inputFillDark, t) ?? inputFillDark,
      selectionBackground:
          Color.lerp(selectionBackground, other.selectionBackground, t) ??
              selectionBackground,
      chipForeground:
          Color.lerp(chipForeground, other.chipForeground, t) ?? chipForeground,
      mutedForeground:
          Color.lerp(mutedForeground, other.mutedForeground, t) ??
              mutedForeground,
      subduedForeground:
          Color.lerp(subduedForeground, other.subduedForeground, t) ??
              subduedForeground,
      whiteOverlay:
          Color.lerp(whiteOverlay, other.whiteOverlay, t) ?? whiteOverlay,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      success: Color.lerp(success, other.success, t) ?? success,
      heroGradientStart:
          Color.lerp(heroGradientStart, other.heroGradientStart, t) ??
              heroGradientStart,
      heroGradientEnd:
          Color.lerp(heroGradientEnd, other.heroGradientEnd, t) ??
              heroGradientEnd,
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
      lightShadow:
          Color.lerp(lightShadow, other.lightShadow, t) ?? lightShadow,
      darkShadow: Color.lerp(darkShadow, other.darkShadow, t) ?? darkShadow,
    );
  }
}

extension AppThemeColorsX on BuildContext {
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>()!;
}
