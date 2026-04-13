import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_json_keys.dart';
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
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('${AppStrings.t('unexpected_error')}: $e');
    }
  }

  Future<void> verifySignUpOtp({
    required String email,
    required String token,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.signup,
      );
    } on AuthException catch (e) {
      throw Exception(_mapOtpError(e.message));
    }
  }

  Future<void> resendSignUpOtp(String email) async {
    try {
      await _client.auth.resend(
        email: email.trim(),
        type: OtpType.signup,
      );
    } on AuthException catch (e) {
      throw Exception(_mapOtpError(e.message));
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
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw Exception(_mapOtpError(e.message));
    }
  }

  Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.recovery,
      );
    } on AuthException catch (e) {
      throw Exception(_mapOtpError(e.message));
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String _mapOtpError(String message) {
    final normalizedMessage = message.toLowerCase();

    if (normalizedMessage.contains('expired')) {
      return AppStrings.t('auth_otp_expired_error');
    }

    if (normalizedMessage.contains('invalid')) {
      return AppStrings.t('auth_otp_invalid_error');
    }

    if (normalizedMessage.contains('over_email_send_rate_limit')) {
      return AppStrings.t('wait_email');
    }

    return message;
  }
}
