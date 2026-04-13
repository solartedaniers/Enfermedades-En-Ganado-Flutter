import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_json_keys.dart';
import '../../../core/constants/app_user_type.dart';
import '../../../core/services/pending_user_registration_service.dart';
import '../../../core/utils/app_strings.dart';

enum AuthRegistrationStatus {
  online,
  queuedOffline,
}

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;
  final PendingUserRegistrationService _pendingRegistrationService =
      PendingUserRegistrationService();

  Future<AuthRegistrationStatus> signUpUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    required String location,
    required AppUserType userType,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedFirstName = firstName.trim();
    final normalizedLastName = lastName.trim();
    final normalizedUsername = username.trim();
    final normalizedPhone = phone.trim();
    final normalizedLocation = location.trim();

    try {
      final existing = await _client
          .from('profiles')
          .select(AppJsonKeys.username)
          .eq(AppJsonKeys.username, normalizedUsername)
          .maybeSingle();

      if (existing != null) {
        throw Exception(AppStrings.t('username_in_use'));
      }

      await _performRemoteSignUp(
        email: normalizedEmail,
        password: password,
        firstName: normalizedFirstName,
        lastName: normalizedLastName,
        username: normalizedUsername,
        phone: normalizedPhone,
        location: normalizedLocation,
        userType: userType,
      );
      return AuthRegistrationStatus.online;
    } on AuthException catch (e) {
      final message = e.message;

      if (_shouldQueueOffline(message)) {
        await _pendingRegistrationService.queueRegistration(
          PendingUserRegistration(
            email: normalizedEmail,
            password: password,
            firstName: normalizedFirstName,
            lastName: normalizedLastName,
            username: normalizedUsername,
            phone: normalizedPhone,
            location: normalizedLocation,
            userType: userType,
            createdAt: DateTime.now(),
          ),
        );
        return AuthRegistrationStatus.queuedOffline;
      }

      if (message.contains('already registered')) {
        throw Exception(AppStrings.t('account_already_exists'));
      }

      if (message.contains('Database error saving new user')) {
        throw Exception(AppStrings.t('profile_save_error'));
      }

      throw Exception(message);
    } catch (e) {
      final normalizedError = e.toString().toLowerCase();
      if (_shouldQueueOffline(normalizedError)) {
        await _pendingRegistrationService.queueRegistration(
          PendingUserRegistration(
            email: normalizedEmail,
            password: password,
            firstName: normalizedFirstName,
            lastName: normalizedLastName,
            username: normalizedUsername,
            phone: normalizedPhone,
            location: normalizedLocation,
            userType: userType,
            createdAt: DateTime.now(),
          ),
        );
        return AuthRegistrationStatus.queuedOffline;
      }

      if (e is Exception) {
        rethrow;
      }

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

  Future<void> syncPendingRegistrations() async {
    final pendingRegistrations =
        await _pendingRegistrationService.getPendingRegistrations();

    for (final registration in pendingRegistrations) {
      try {
        await _performRemoteSignUp(
          email: registration.email,
          password: registration.password,
          firstName: registration.firstName,
          lastName: registration.lastName,
          username: registration.username,
          phone: registration.phone,
          location: registration.location,
          userType: registration.userType,
        );
        await _pendingRegistrationService.removeRegistration(registration.email);
      } on AuthException catch (error) {
        if (error.message.contains('already registered')) {
          await _pendingRegistrationService.removeRegistration(registration.email);
          continue;
        }

        rethrow;
      }
    }
  }

  Future<void> _performRemoteSignUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    required String location,
    required AppUserType userType,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        AppJsonKeys.firstName: firstName,
        AppJsonKeys.lastName: lastName,
        AppJsonKeys.fullName: '$firstName $lastName'.trim(),
        AppJsonKeys.name: firstName,
        AppJsonKeys.username: username,
        AppJsonKeys.phone: phone,
        AppJsonKeys.location: location,
        AppJsonKeys.userType: userType.storageValue,
      },
    );
  }

  bool _shouldQueueOffline(String message) {
    final normalizedMessage = message.toLowerCase();

    return normalizedMessage.contains('failed host lookup') ||
        normalizedMessage.contains('socketexception') ||
        normalizedMessage.contains('network is unreachable') ||
        normalizedMessage.contains('network request failed') ||
        normalizedMessage.contains('xmlhttprequest error') ||
        normalizedMessage.contains('connection closed before full header was received') ||
        normalizedMessage.contains('clientexception') ||
        normalizedMessage.contains('timed out');
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
