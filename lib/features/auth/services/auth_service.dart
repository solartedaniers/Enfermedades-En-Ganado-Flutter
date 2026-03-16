import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// =========================
  /// REGISTRAR USUARIO (Optimizado)
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
      // 1. Verificar disponibilidad de username
      final existing = await _client
          .from('profiles')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (existing != null) {
        throw Exception("El nombre de usuario ya está en uso");
      }

      // 2. Registro en Auth con Metadata
      // Los datos en 'data' serán procesados por el Trigger de SQL
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
          'phone': phone,
          'location': location,
          'user_type': userType,
        },
      );

      if (response.user == null) {
        throw Exception("No se pudo crear la cuenta");
      }
      
    } on AuthException catch (e) {
      // Errores específicos de Supabase
      if (e.message.contains("already registered")) {
        throw Exception("Ya existe una cuenta con este correo");
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Ocurrió un error inesperado: $e");
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
    } on AuthException catch (e) {
      if (e.message.contains("Invalid login credentials")) {
        throw Exception("Correo o contraseña incorrectos");
      }
      if (e.message.contains("Email not confirmed")) {
        throw Exception("Debes confirmar tu correo antes de iniciar sesión");
      }
      throw Exception(e.message);
    } catch (e) {
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
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Error al procesar la solicgdgitud");
    }
  }

  /// =========================
  /// CERRAR SESIÓN
  /// =========================
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}