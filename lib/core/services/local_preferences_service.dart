import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_storage_keys.dart';

class LocalPreferencesSnapshot {
  final String language;
  final ThemeMode themeMode;

  const LocalPreferencesSnapshot({
    required this.language,
    required this.themeMode,
  });
}

class LocalPreferencesService {
  const LocalPreferencesService._();

  static const String defaultLanguage = 'es';
  static const ThemeMode defaultThemeMode = ThemeMode.system;

  static Future<LocalPreferencesSnapshot> load({String? scope}) async {
    final prefs = await SharedPreferences.getInstance();
    final languageKey = _languageKey(scope);
    final themeModeKey = _themeModeKey(scope);
    final language =
        prefs.getString(languageKey) ??
            prefs.getString(AppStorageKeys.preferredLanguage) ??
            defaultLanguage;
    final themeModeName =
        prefs.getString(themeModeKey) ??
            prefs.getString(AppStorageKeys.preferredThemeMode) ??
            defaultThemeMode.name;

    return LocalPreferencesSnapshot(
      language: language,
      themeMode: _themeModeFromName(themeModeName),
    );
  }

  static Future<void> saveLanguage(String language, {String? scope}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppStorageKeys.preferredLanguage, language);
    if (scope != null && scope.isNotEmpty) {
      await prefs.setString(_languageKey(scope), language);
    }
  }

  static Future<void> saveThemeMode(ThemeMode themeMode, {String? scope}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppStorageKeys.preferredThemeMode,
      themeMode.name,
    );
    if (scope != null && scope.isNotEmpty) {
      await prefs.setString(_themeModeKey(scope), themeMode.name);
    }
  }

  static String? scopeFromIdentity({
    String? email,
    String? userId,
  }) {
    final normalizedEmail = email?.trim().toLowerCase();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      return normalizedEmail;
    }

    final normalizedUserId = userId?.trim();
    if (normalizedUserId != null && normalizedUserId.isNotEmpty) {
      return normalizedUserId;
    }

    return null;
  }

  static ThemeMode _themeModeFromName(String themeModeName) {
    for (final themeMode in ThemeMode.values) {
      if (themeMode.name == themeModeName) {
        return themeMode;
      }
    }

    return defaultThemeMode;
  }

  static String _languageKey(String? scope) {
    if (scope == null || scope.isEmpty) {
      return AppStorageKeys.preferredLanguage;
    }

    return '${AppStorageKeys.preferredLanguageScopePrefix}$scope';
  }

  static String _themeModeKey(String? scope) {
    if (scope == null || scope.isEmpty) {
      return AppStorageKeys.preferredThemeMode;
    }

    return '${AppStorageKeys.preferredThemeModeScopePrefix}$scope';
  }
}
