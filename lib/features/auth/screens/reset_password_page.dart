import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import 'login_page.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _supabase = Supabase.instance.client;

  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _passwordUpdated = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final pass = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pass.isEmpty || pass.length < 8) {
      _showSnackBar(AppStrings.t("password_min_8"));
      return;
    }
    if (pass != confirm) {
      _showSnackBar(AppStrings.t("passwords_no_match"));
      return;
    }

    setState(() => _loading = true);

    try {
      await _supabase.auth.updateUser(UserAttributes(password: pass));
      
      if (!mounted) return;

      setState(() {
        _loading = false;
        _passwordUpdated = true;
      });

      _showSnackBar(AppStrings.t("password_updated"));

      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;

      await _supabase.auth.signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnackBar(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnackBar(AppStrings.t("unexpected_error"));
    }
  }

  Future<void> _cancel() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.primaryColor;
    const darkGreen = Color(0xFF1B4332);
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF1F8F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Ícono Animado ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _passwordUpdated
                        ? Colors.green.withValues(alpha: 0.1)
                        : primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _passwordUpdated
                        ? Icons.check_circle_rounded
                        : Icons.lock_reset_rounded,
                    size: 70,
                    color: _passwordUpdated ? Colors.green : primary,
                  ),
                )
                    .animate(target: _passwordUpdated ? 1 : 0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 300.ms,
                    ),
                const SizedBox(height: 28),

                Text(
                  _passwordUpdated
                      ? AppStrings.t("password_updated")
                      : AppStrings.t("new_password"),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : darkGreen,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 8),
                Text(
                  _passwordUpdated
                      ? "Redirigiendo al inicio de sesión..."
                      : AppStrings.t("new_password_subtitle"),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ).animate().fadeIn(delay: 100.ms),

                if (!_passwordUpdated) ...[
                  const SizedBox(height: 36),
                  _buildField(
                    controller: _passwordController,
                    label: AppStrings.t("new_password_field"),
                    icon: Icons.lock_outline,
                    obscure: !_showPassword,
                    suffix: IconButton(
                      icon: Icon(_showPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                    isDark: isDark,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

                  const SizedBox(height: 16),
                  _buildField(
                    controller: _confirmController,
                    label: AppStrings.t("confirm_password_field"),
                    icon: Icons.verified_user_outlined,
                    obscure: !_showConfirm,
                    suffix: IconButton(
                      icon: Icon(_showConfirm
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _showConfirm = !_showConfirm),
                    ),
                    isDark: isDark,
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _updatePassword,
                      child: _loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              AppStrings.t("update_exit"),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 20),
                  // Botón de Cancelar vinculado correctamente
                  TextButton(
                    onPressed: _cancel,
                    child: Text(
                      AppStrings.t("cancel_process"),
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                if (_passwordUpdated)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: CircularProgressIndicator(),
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
    bool obscure = false,
    Widget? suffix,
    required bool isDark,
  }) {
    final primary = AppTheme.primaryColor;
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primary),
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark
                  ? const Color(0xFF3A3A3A)
                  : const Color(0xFFDEE2E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}