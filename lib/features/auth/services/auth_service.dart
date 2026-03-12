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
    try {

      // Verificar si username ya existe
      final existingUsername = await _client
          .from('profiles')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (existingUsername != null) {
        throw Exception("El nombre de usuario ya existe");
      }

      // Registrar usuario en Supabase Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        throw Exception("No se pudo crear la cuenta");
      }

      // Crear perfil en tabla profiles
      await _client.from('profiles').insert({
        'id': user.id,
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'phone': phone,
        'location': location,
        'user_type': userType,
      });

    } on AuthException catch (e) {

      // Correo ya registrado
      if (e.message.contains("User already registered")) {
        throw Exception("Ya existe una cuenta con este correo");
      }

      // Límite de correos
      if (e.message.contains("over_email_send_rate_limit")) {
        throw Exception(
            "Debes esperar unos segundos antes de solicitar otro correo de verificación");
      }

      throw Exception(e.message);
    }
  }

  /// Iniciar sesión
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

      if (e.message.contains("Invalid login credentials")) {
        throw Exception("Correo o contraseña incorrectos");
      }

      if (e.message.contains("Email not confirmed")) {
        throw Exception("Debes confirmar tu correo antes de iniciar sesión");
      }

      throw Exception(e.message);
    }
  }

  /// Resetear contraseña
  Future<void> resetPassword(String email) async {
    try {

      await _client.auth.resetPasswordForEmail(email);

    } on AuthException catch (e) {

      if (e.message.contains("User not found")) {
        throw Exception("No existe una cuenta con ese correo");
      }

      if (e.message.contains("over_email_send_rate_limit")) {
        throw Exception(
            "Debes esperar unos segundos antes de solicitar otro correo");
      }

      throw Exception(e.message);
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}