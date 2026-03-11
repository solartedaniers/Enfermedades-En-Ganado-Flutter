import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // Iniciar sesión con email y contraseña
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Registro básico (solo email y password)
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Registro completo con datos adicionales en la tabla profiles
  Future<void> signUpUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user != null) {
      await _client.from('profiles').insert({
        'id': user.id,
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
      });
    }
  }

  // Resetear contraseña por email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}