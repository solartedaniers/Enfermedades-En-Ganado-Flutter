import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {

  final SupabaseClient _client = Supabase.instance.client;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {

    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {

    await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> resetPassword(String email) async {

    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {

    await _client.auth.signOut();
  }

}