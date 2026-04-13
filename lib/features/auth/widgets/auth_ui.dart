import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

extension AuthUiContext on BuildContext {
  ThemeData get authTheme => Theme.of(this);

  ColorScheme get authColorScheme => authTheme.colorScheme;

  AppThemeColors get authColors => appColors;

  Color get authTitleColor => authColorScheme.onSurface;

  Color get authPrimaryColor => authColorScheme.primary;

  Color get authPrimaryTint => authPrimaryColor.withValues(alpha: 0.1);

  Color get authInteractiveColor =>
      authTheme.brightness == Brightness.dark
          ? authColors.accent
          : authColors.heroGradientStart;

  TextStyle get authPrimaryButtonTextStyle => const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        letterSpacing: 1.1,
      );
}
