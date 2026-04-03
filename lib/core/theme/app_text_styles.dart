import 'package:flutter/material.dart';

class AppTextStyles {
  static TextStyle sectionTitle(ThemeData theme) {
    return theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ) ??
        const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        );
  }

  static TextStyle emphasisLabel(ThemeData theme, Color color) {
    return theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ) ??
        TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: color,
        );
  }

  static TextStyle caption(ThemeData theme, Color color) {
    return theme.textTheme.bodySmall?.copyWith(
          color: color,
        ) ??
        TextStyle(
          fontSize: 12,
          color: color,
        );
  }
}
