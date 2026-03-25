import 'package:supabase_flutter/supabase_flutter.dart';

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
    required String userType,
  }) async {
    try {
      final normalizedFirstName = firstName.trim();
      final normalizedLastName = lastName.trim();
      final normalizedUsername = username.trim();
      final normalizedPhone = phone.trim();
      final normalizedLocation = location.trim();
      final normalizedUserType = _normalizeUserType(userType);

      final existing = await _client
          .from('profiles')
          .select('username')
          .eq('username', normalizedUsername)
          .maybeSingle();

      if (existing != null) {
        throw Exception('El nombre de usuario ya esta en uso');
      }

      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: 'agrovetai://auth-confirm',
        data: {
          'first_name': normalizedFirstName,
          'last_name': normalizedLastName,
          'full_name': '$normalizedFirstName $normalizedLastName'.trim(),
          'name': normalizedFirstName,
          'username': normalizedUsername,
          'phone': normalizedPhone,
          'location': normalizedLocation,
          'user_type': normalizedUserType,
          'language': 'es',
          'theme': 'system',
        },
      );
    } on AuthException catch (e) {
      final message = e.message;

      if (message.contains('already registered')) {
        throw Exception('Ya existe una cuenta con este correo');
      }

      if (message.contains('Database error saving new user')) {
        throw Exception(
          'Supabase rechazo el guardado inicial del perfil. Revisa la tabla o trigger de profiles, especialmente el campo user_type.',
        );
      }

      throw Exception(message);
    } catch (e) {
      throw Exception('Ocurrio un error inesperado: $e');
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
        throw Exception('Correo o contrasena incorrectos');
      }
      if (e.message.contains('Email not confirmed')) {
        throw Exception('Debes confirmar tu correo antes de iniciar sesion');
      }
      throw Exception(e.message);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'agrovetai://reset-password',
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String _normalizeUserType(String value) {
    switch (value.trim().toLowerCase()) {
      case 'ganadero':
      case 'farmer':
        return 'farmer';
      case 'veterinario':
      case 'veterinarian':
        return 'veterinarian';
      default:
        return value.trim().toLowerCase();
    }
  }
}
