import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Registrar usuario y crear perfil
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
    // Verificar username existente
    final existing = await _client
        .from('profiles')
        .select()
        .eq('username', username)
        .maybeSingle();

    if (existing != null) {
      throw Exception("El nombre de usuario ya existe");
    }

    // Registrar usuario en auth
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
        'phone': phone,
        'location': location,
        'user_type': userType,
      });
    }
  }

  /// Iniciar sesión
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Resetear contraseña
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}