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
      // 1. Verificar disponibilidad de username
      final existing = await _client
          .from('profiles')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (existing != null) {
        throw Exception("El nombre de usuario ya está en uso");
      }

      // 2. Registro en Auth con Metadata y redirección exacta al host de Android
      await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'agrovetai://auth-confirm', // 👈 Coincide con AndroidManifest
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
          'phone': phone,
          'location': location,
          'user_type': userType,
        },
      );
      
    } on AuthException catch (e) {
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
    }
  }

  /// =========================
  /// RECUPERAR CONTRASEÑA
  /// =========================
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: "agrovetai://reset-password", // 👈 Coincide con AndroidManifest
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}