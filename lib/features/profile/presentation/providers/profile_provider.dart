import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/services/offline_auth_service.dart';

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

  factory ProfileState.empty() => ProfileState(
        name: AppStrings.t('default_username'),
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

  void _listenToAuthChanges() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        await _loadFromSupabase();
      } else if (event == AuthChangeEvent.signedOut) {
        await AppStrings.load('es');
        await OfflineAuthService.clearSession();
        state = ProfileState.empty();
      }
    });

    if (_supabase.auth.currentUser != null) {
      _loadFromSupabase();
    }
  }

  Future<void> _loadFromSupabase() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        await AppStrings.load('es');
        state = ProfileState.empty();
        return;
      }

      final data = await _supabase
          .from('profiles')
          .select('username, avatar_url, language, theme')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (data == null) {
        final meta = currentUser.userMetadata;
        final name =
            (meta?['username'] as String?) ?? AppStrings.t('default_username');
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
      final theme = (data['theme'] as String?) ?? 'system';
      final name =
          (data['username'] as String?) ?? AppStrings.t('default_username');
      final avatar = data['avatar_url'] as String?;

      await AppStrings.load(lang);

      // Guarda sesión offline
      await OfflineAuthService.saveSession(
        userId: currentUser.id,
        userName: name,
        avatarUrl: avatar,
        language: lang,
        theme: theme,
      );

      state = ProfileState(
        name: name,
        avatarUrl: avatar,
        language: lang,
        themeMode: _themeFromString(theme),
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
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;
      await _supabase.from('profiles').update(data).eq('id', currentUser.id);
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
