import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_json_keys.dart';
import '../../../core/constants/app_route_paths.dart';
import '../../../core/constants/app_user_type.dart';
import '../../../core/utils/app_strings.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> signUpUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    required String location,
    required AppUserType userType,
  }) async {
    try {
      final normalizedFirstName = firstName.trim();
      final normalizedLastName = lastName.trim();
      final normalizedUsername = username.trim();
      final normalizedPhone = phone.trim();
      final normalizedLocation = location.trim();
      final existing = await _client
          .from('profiles')
          .select(AppJsonKeys.username)
          .eq(AppJsonKeys.username, normalizedUsername)
          .maybeSingle();

      if (existing != null) {
        throw Exception(AppStrings.t('username_in_use'));
      }

      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: AppDeepLinkPaths.authConfirm,
        data: {
          AppJsonKeys.firstName: normalizedFirstName,
          AppJsonKeys.lastName: normalizedLastName,
          AppJsonKeys.fullName: '$normalizedFirstName $normalizedLastName'.trim(),
          AppJsonKeys.name: normalizedFirstName,
          AppJsonKeys.username: normalizedUsername,
          AppJsonKeys.phone: normalizedPhone,
          AppJsonKeys.location: normalizedLocation,
          AppJsonKeys.userType: userType.storageValue,
        },
      );
    } on AuthException catch (e) {
      final message = e.message;

      if (message.contains('already registered')) {
        throw Exception(AppStrings.t('account_already_exists'));
      }

      if (message.contains('Database error saving new user')) {
        throw Exception(AppStrings.t('profile_save_error'));
      }

      throw Exception(message);
    } catch (e) {
      throw Exception('${AppStrings.t('unexpected_error')}: $e');
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw Exception(AppStrings.t('invalid_login'));
      }
      if (e.message.contains('Email not confirmed')) {
        throw Exception(AppStrings.t('confirm_email_first'));
      }
      throw Exception(e.message);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: AppDeepLinkPaths.resetPassword,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
