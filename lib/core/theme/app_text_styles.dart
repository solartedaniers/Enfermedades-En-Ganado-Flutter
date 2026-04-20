import 'package:flutter/material.dart';

class AppTextStyles {
  static TextStyle title(ThemeData theme) {
    return theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ) ??
        const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        );
  }

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

  static TextStyle bodyMuted(ThemeData theme, Color color) {
    return theme.textTheme.bodyMedium?.copyWith(
          color: color,
        ) ??
        TextStyle(
          fontSize: 14,
          color: color,
        );
  }

  static TextStyle bodyStrong(ThemeData theme, Color color) {
    return theme.textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          fontSize: 14,
          color: color,
          fontWeight: FontWeight.w600,
        );
  }
}
