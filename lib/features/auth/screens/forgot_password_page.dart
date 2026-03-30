import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/auth_page_shell.dart';
import '../widgets/auth_text_field.dart';
import '../../profile/presentation/providers/profile_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final emailController = TextEditingController();
  final authService = AuthService();
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> reset() async {
    if (emailController.text.isEmpty) {
      _showSnackBar(AppStrings.t("enter_email_field"));
      return;
    }
    setState(() => loading = true);
    try {
      await authService.resetPassword(emailController.text.trim());
      if (!mounted) return;
      _showSnackBar(AppStrings.t("email_sent"));
      Future.delayed(
          const Duration(seconds: 2), () => mounted ? Navigator.pop(context) : null);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceAll("Exception: ", ""));
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
    final theme = Theme.of(context);
    final appColors = context.appColors;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? colorScheme.onSurface : colorScheme.onSurface;

    return AuthPageShell(
      appBar: AppBar(
        title: Text(AppStrings.t("recover_access"),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: titleColor,
        elevation: 0,
        centerTitle: true,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 70,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            AppStrings.t("forgot_title"),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.t("forgot_subtitle"),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: appColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 40),
          AuthTextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            label: AppStrings.t("email"),
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: loading ? null : reset,
              child: loading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(AppStrings.t("send_instructions"),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.1)),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.t("back_to_login"),
              style: TextStyle(
                  color: isDark ? appColors.accent : appColors.heroGradientStart,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
