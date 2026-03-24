import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_strings.dart';

class ProfileState {
  final String name;
  final String language;
  final ThemeMode themeMode;
  final String? avatarUrl;
  final bool isLoaded;

  ProfileState({
    required this.name,
    required this.language,
    required this.themeMode,
    this.avatarUrl,
    this.isLoaded = false,
  });

  ProfileState copyWith({
    String? name,
    String? language,
    ThemeMode? themeMode,
    String? avatarUrl,
    bool? isLoaded,
    bool clearAvatar = false,
  }) {
    return ProfileState(
      name: name ?? this.name,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      avatarUrl: clearAvatar ? null : avatarUrl ?? this.avatarUrl,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier()
      : super(ProfileState(
          name: "Usuario",
          language: "es",
          themeMode: ThemeMode.system,
          isLoaded: false,
        )) {
    _loadFromSupabase();
  }

  final _supabase = Supabase.instance.client;

  Future<void> _loadFromSupabase() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await AppStrings.load('es');
        return;
      }

      final data = await _supabase
          .from('profiles')
          .select('username, avatar_url, language, theme')
          .eq('id', user.id)
          .single();

      final lang = (data['language'] as String?) ?? 'es';
      final theme = (data['theme'] as String?) ?? 'system';
      final name = (data['username'] as String?) ?? 'Usuario';
      final avatar = data['avatar_url'] as String?;

      await AppStrings.load(lang);

      state = state.copyWith(
        name: name,
        avatarUrl: avatar,
        language: lang,
        themeMode: _themeFromString(theme),
        isLoaded: true,
      );
    } catch (e) {
      await AppStrings.load('es');
      state = state.copyWith(isLoaded: true);
    }
  }

  // Recarga forzada desde Supabase (útil al volver al home)
  Future<void> reload() async {
    await _loadFromSupabase();
  }

  Future<void> _saveToSupabase(Map<String, dynamic> data) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase.from('profiles').update(data).eq('id', user.id);
    } catch (e) {
      // fallo silencioso
    }
  }

  Future<void> changeName(String name) async {
    state = state.copyWith(name: name);
    await _saveToSupabase({'username': name});
  }

  Future<void> changeLanguage(String lang) async {
    await AppStrings.load(lang);
    state = state.copyWith(language: lang);
    await _saveToSupabase({'language': lang});
  }

  Future<void> changeTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveToSupabase({'theme': _themeToString(mode)});
  }

  Future<void> changeAvatar(String url) async {
    state = state.copyWith(avatarUrl: url);
    await _saveToSupabase({'avatar_url': url});
  }

  ThemeMode _themeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(),
);