import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../widgets/auth_page_shell.dart';
import '../widgets/auth_text_field.dart';
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
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnackBar(error.message);
    } catch (_) {
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = context.appColors;
    final isDark = theme.brightness == Brightness.dark;

    return AuthPageShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (_passwordUpdated ? appColors.success : AppTheme.primaryColor)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _passwordUpdated
                  ? Icons.check_circle_rounded
                  : Icons.lock_reset_rounded,
              size: 70,
              color: _passwordUpdated ? appColors.success : AppTheme.primaryColor,
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
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? colorScheme.onSurface : appColors.heroGradientStart,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            _passwordUpdated
                ? AppStrings.t("reset_password_redirecting")
                : AppStrings.t("new_password_subtitle"),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: appColors.mutedForeground,
            ),
          ).animate().fadeIn(delay: 100.ms),
          if (!_passwordUpdated) ...[
            const SizedBox(height: 36),
            AuthTextField(
              controller: _passwordController,
              label: AppStrings.t("new_password_field"),
              icon: Icons.lock_outline,
              obscureText: !_showPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _confirmController,
              label: AppStrings.t("confirm_password_field"),
              icon: Icons.verified_user_outlined,
              obscureText: !_showConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _showConfirm ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _showConfirm = !_showConfirm),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _loading ? null : _updatePassword,
                child: _loading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
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
            TextButton(
              onPressed: _cancel,
              child: Text(
                AppStrings.t("cancel_process"),
                style: TextStyle(
                  color: appColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (_passwordUpdated)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
        ],
      ),
    );
  }
}
