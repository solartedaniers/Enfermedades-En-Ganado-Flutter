import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_json_keys.dart';
import '../../../../core/constants/app_user_type.dart';
import '../../../../core/services/local_preferences_service.dart';
import '../../../../core/services/offline_auth_service.dart';
import '../../../../core/utils/app_strings.dart';

class ProfileState {
  final String? userId;
  final String name;
  final String email;
  final String language;
  final AppUserType userType;
  final ThemeMode themeMode;
  final String? avatarUrl;
  final bool isLoaded;

  const ProfileState({
    required this.userId,
    required this.name,
    required this.email,
    required this.language,
    required this.userType,
    required this.themeMode,
    this.avatarUrl,
    this.isLoaded = false,
  });

  ProfileState copyWith({
    String? userId,
    bool clearUserId = false,
    String? name,
    String? email,
    String? language,
    AppUserType? userType,
    ThemeMode? themeMode,
    String? avatarUrl,
    bool? isLoaded,
    bool clearAvatar = false,
  }) {
    return ProfileState(
      userId: clearUserId ? null : userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      language: language ?? this.language,
      userType: userType ?? this.userType,
      themeMode: themeMode ?? this.themeMode,
      avatarUrl: clearAvatar ? null : avatarUrl ?? this.avatarUrl,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  factory ProfileState.empty() => ProfileState(
        userId: null,
        name: AppStrings.t('default_username'),
        email: '',
        language: 'es',
        userType: AppUserType.farmer,
        themeMode: ThemeMode.system,
        avatarUrl: null,
        isLoaded: false,
      );

  bool get isVeterinarian => userType.isVeterinarian;
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier({
    required LocalPreferencesSnapshot initialPreferences,
  }) : super(
         ProfileState.empty().copyWith(
           language: initialPreferences.language,
           themeMode: initialPreferences.themeMode,
         ),
       ) {
    _listenToAuthChanges();
  }

  final _supabase = Supabase.instance.client;

  String? get _preferenceScope {
    return LocalPreferencesService.scopeFromIdentity(
      email: state.email,
      userId: state.userId,
    );
  }

  void _listenToAuthChanges() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        await _loadFromSupabase();
      } else if (event == AuthChangeEvent.signedOut) {
        final currentLanguage = state.language;
        final currentThemeMode = state.themeMode;
        await AppStrings.load(currentLanguage);
        state = ProfileState.empty().copyWith(
          language: currentLanguage,
          themeMode: currentThemeMode,
          isLoaded: true,
        );
      }
    });

    if (_supabase.auth.currentUser != null) {
      _loadFromSupabase();
    }
  }

  Future<void> _loadFromSupabase() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      final scopedPreferences = await LocalPreferencesService.load(
        scope: LocalPreferencesService.scopeFromIdentity(
          email: currentUser?.email,
          userId: currentUser?.id,
        ),
      );
      final currentLanguage = scopedPreferences.language;
      final currentThemeMode = scopedPreferences.themeMode;

      if (currentUser == null) {
        await AppStrings.load(currentLanguage);
        state = ProfileState.empty().copyWith(
          language: currentLanguage,
          themeMode: currentThemeMode,
          isLoaded: true,
        );
        return;
      }

      final data = await _supabase
          .from('profiles')
          .select('${AppJsonKeys.username}, avatar_url, ${AppJsonKeys.userType}')
          .eq('id', currentUser.id)
          .maybeSingle();

      await AppStrings.load(currentLanguage);

      if (data == null) {
        final meta = currentUser.userMetadata;
        final name =
            (meta?[AppJsonKeys.username] as String?) ??
                AppStrings.t('default_username');
        final userType = AppUserTypeCodec.fromValue(
          meta?[AppJsonKeys.userType] as String?,
        );

        state = ProfileState(
          userId: currentUser.id,
          name: name,
          email: currentUser.email ?? '',
          language: currentLanguage,
          userType: userType,
          themeMode: currentThemeMode,
          avatarUrl: null,
          isLoaded: true,
        );
        return;
      }

      final userType = AppUserTypeCodec.fromValue(
        data[AppJsonKeys.userType] as String?,
      );
      final name =
          (data[AppJsonKeys.username] as String?) ??
              AppStrings.t('default_username');
      final avatar = data['avatar_url'] as String?;

      await OfflineAuthService.saveSession(
        userId: currentUser.id,
        userName: name,
        userType: userType.storageValue,
        avatarUrl: avatar,
      );

      state = ProfileState(
        userId: currentUser.id,
        name: name,
        email: currentUser.email ?? '',
        avatarUrl: avatar,
        language: currentLanguage,
        userType: userType,
        themeMode: currentThemeMode,
        isLoaded: true,
      );
    } catch (_) {
      await AppStrings.load(state.language);
      state = ProfileState.empty().copyWith(
        language: state.language,
        themeMode: state.themeMode,
        isLoaded: true,
      );
    }
  }

  Future<void> reload() => _loadFromSupabase();

  Future<void> _saveToSupabase(Map<String, dynamic> data) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return;
      }

      await _supabase.from('profiles').update(data).eq('id', currentUser.id);
    } catch (_) {}
  }

  Future<void> changeName(String name) async {
    state = state.copyWith(name: name);
    await _saveToSupabase({'username': name});
  }

  Future<void> changeLanguage(String language) async {
    await AppStrings.load(language);
    state = state.copyWith(language: language);
    await LocalPreferencesService.saveLanguage(
      language,
      scope: _preferenceScope,
    );
  }

  Future<void> changeTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await LocalPreferencesService.saveThemeMode(
      mode,
      scope: _preferenceScope,
    );
  }

  Future<void> changeAvatar(String url) async {
    state = state.copyWith(avatarUrl: url);
    await _saveToSupabase({'avatar_url': url});
  }

  Future<void> cacheOfflineAccess({
    required String email,
    required String password,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      return;
    }

    await OfflineAuthService.saveOfflineAccess(
      userId: currentUser.id,
      userName: state.name,
      userType: state.userType.storageValue,
      email: email,
      password: password,
      avatarUrl: state.avatarUrl,
    );
  }

  Future<bool> activateOfflineSession({
    required String email,
    required String password,
  }) async {
    final offlineSnapshot = await OfflineAuthService.authenticateOffline(
      email: email,
      password: password,
    );

    if (offlineSnapshot == null || offlineSnapshot['userId'] == null) {
      return false;
    }

    final scopedPreferences = await LocalPreferencesService.load(
      scope: LocalPreferencesService.scopeFromIdentity(email: email),
    );
    await AppStrings.load(scopedPreferences.language);

    state = state.copyWith(
      userId: offlineSnapshot['userId'],
      name: offlineSnapshot['userName'] ?? AppStrings.t('default_username'),
      email: offlineSnapshot['email'] ?? email.trim(),
      language: scopedPreferences.language,
      themeMode: scopedPreferences.themeMode,
      userType: AppUserTypeCodec.fromValue(offlineSnapshot['userType']),
      avatarUrl: offlineSnapshot['avatarUrl'],
      isLoaded: true,
    );

    return true;
  }
}

final profilePreferencesProvider = Provider<LocalPreferencesSnapshot>(
  (ref) => const LocalPreferencesSnapshot(
    language: LocalPreferencesService.defaultLanguage,
    themeMode: LocalPreferencesService.defaultThemeMode,
  ),
);

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(
    initialPreferences: ref.watch(profilePreferencesProvider),
  ),
);
