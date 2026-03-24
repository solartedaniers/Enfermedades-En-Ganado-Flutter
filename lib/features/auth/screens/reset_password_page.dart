import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../profile/presentation/providers/profile_provider.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() =>
      _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final supabase = Supabase.instance.client;

  bool loading = false;
  bool showPassword = false;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        supabase.auth.onAuthStateChange.listen((data) {});
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> updatePassword() async {
    final pass = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (pass.isEmpty || pass.length < 8) {
      _showSnackBar(AppStrings.t("password_min_8"));
      return;
    }
    if (pass != confirm) {
      _showSnackBar(AppStrings.t("passwords_no_match"));
      return;
    }
    setState(() => loading = true);
    try {
      await supabase.auth.updateUser(UserAttributes(password: pass));
      if (!mounted) return;
      _showSnackBar(AppStrings.t("password_updated"));
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
          context, '/login', (route) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(AppStrings.t("unexpected_error"));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen = AppTheme.primaryColor;
    final darkGreen = const Color(0xFF1B4332);
    final bgColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF1F8F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(AppStrings.t("reset_password"),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : darkGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_reset_rounded,
                      size: 60, color: primaryGreen),
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.t("new_password"),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : darkGreen),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.t("new_password_subtitle"),
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),
                _buildField(
                  controller: passwordController,
                  label: AppStrings.t("new_password_field"),
                  icon: Icons.lock_outline,
                  obscure: !showPassword,
                  primaryGreen: primaryGreen,
                  suffix: IconButton(
                    icon: Icon(showPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => showPassword = !showPassword),
                  ),
                ),
                const SizedBox(height: 20),
                _buildField(
                  controller: confirmController,
                  label: AppStrings.t("confirm_password_field"),
                  icon: Icons.verified_user_outlined,
                  obscure: true,
                  primaryGreen: primaryGreen,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: loading ? null : updatePassword,
                    child: loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(AppStrings.t("update_exit"),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.1)),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppStrings.t("cancel_process"),
                    style: TextStyle(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryGreen,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryGreen),
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        suffixIcon: suffix,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 2),
        ),
      ),
    );
  }
}