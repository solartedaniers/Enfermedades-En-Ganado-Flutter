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

  // Estado limpio para cuando no hay sesión o se cierra sesión
  factory ProfileState.empty() => ProfileState(
        name: "Usuario",
        language: "es",
        themeMode: ThemeMode.system,
        avatarUrl: null,
        isLoaded: false,
      );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(ProfileState.empty()) {
    _listenToAuthChanges();
  }

  final _supabase = Supabase.instance.client;

  // Escucha cambios de sesión para limpiar/cargar perfil automáticamente
  void _listenToAuthChanges() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        await _loadFromSupabase();
      } else if (event == AuthChangeEvent.signedOut) {
        // Limpia el estado completamente al cerrar sesión
        await AppStrings.load('es');
        state = ProfileState.empty();
      }
    });

    // Carga inicial si ya hay sesión activa
    if (_supabase.auth.currentUser != null) {
      _loadFromSupabase();
    }
  }

  Future<void> _loadFromSupabase() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await AppStrings.load('es');
        state = ProfileState.empty();
        return;
      }

      final data = await _supabase
          .from('profiles')
          .select('username, avatar_url, language, theme')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        // El perfil aún no existe, usa datos de auth metadata
        final meta = user.userMetadata;
        final name = meta?['username'] ?? meta?['first_name'] ?? 'Usuario';
        await AppStrings.load('es');
        state = ProfileState(
          name: name,
          language: 'es',
          themeMode: ThemeMode.system,
          avatarUrl: null,
          isLoaded: true,
        );
        return;
      }

      final lang = (data['language'] as String?) ?? 'es';
      await AppStrings.load(lang);

      state = ProfileState(
        name: (data['username'] as String?) ?? 'Usuario',
        avatarUrl: data['avatar_url'] as String?,
        language: lang,
        themeMode: _themeFromString(data['theme'] ?? 'system'),
        isLoaded: true,
      );
    } catch (e) {
      await AppStrings.load('es');
      state = ProfileState.empty().copyWith(isLoaded: true);
    }
  }

  Future<void> reload() => _loadFromSupabase();

  Future<void> _saveToSupabase(Map<String, dynamic> data) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase.from('profiles').update(data).eq('id', user.id);
    } catch (_) {}
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