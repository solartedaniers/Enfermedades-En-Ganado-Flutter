import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {

    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return response;
  }

}