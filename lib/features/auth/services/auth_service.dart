import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {

  final SupabaseClient _client = Supabase.instance.client;

  /// =========================
  /// REGISTRAR USUARIO
  /// =========================
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

      /// Verificar si username ya existe
      final existingUsername = await _client
          .from('profiles')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (existingUsername != null) {
        throw Exception("El nombre de usuario ya está en uso");
      }

      /// Registrar usuario en Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        throw Exception("No se pudo crear la cuenta");
      }

      /// Crear perfil
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

    /// ERRORES DE SUPABASE AUTH
    on AuthException catch (e) {

      if (e.message.contains("already registered")) {
        throw Exception("Ya existe una cuenta con este correo");
      }

      if (e.message.contains("over_email_send_rate_limit")) {
        throw Exception(
            "Debes esperar unos segundos antes de solicitar otro correo de verificación");
      }

      throw Exception("No se pudo crear la cuenta");

    }

    catch (e) {

      throw Exception("Ocurrió un error al registrar el usuario");

    }

  }

  /// =========================
  /// LOGIN
  /// =========================
  Future<void> signIn({
    required String email,
    required String password,
  }) async {

    try {

      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

    }

    on AuthException catch (e) {

      if (e.message.contains("Invalid login credentials")) {
        throw Exception("Correo o contraseña incorrectos");
      }

      if (e.message.contains("Email not confirmed")) {
        throw Exception("Debes confirmar tu correo antes de iniciar sesión");
      }

      throw Exception("No se pudo iniciar sesión");

    }

    catch (e) {

      throw Exception("Ocurrió un error al iniciar sesión");

    }

  }

  /// =========================
  /// RECUPERAR CONTRASEÑA
  /// =========================
  Future<void> resetPassword(String email) async {

    try {

      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: "agrovetai://reset-password",
      );

    }

    on AuthException catch (e) {

      if (e.message.contains("User not found")) {
        throw Exception("No existe una cuenta con ese correo");
      }

      if (e.message.contains("over_email_send_rate_limit")) {
        throw Exception(
            "Debes esperar unos segundos antes de solicitar otro correo");
      }

      throw Exception("No se pudo enviar el correo");

    }

    catch (e) {

      throw Exception("Ocurrió un error al recuperar la contraseña");

    }

  }

  /// =========================
  /// CERRAR SESIÓN
  /// =========================
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

}