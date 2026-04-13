import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_strings.dart';
import '../models/auth_otp_flow.dart';
import '../services/auth_service.dart';
import '../widgets/auth_page_shell.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_ui.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import 'auth_otp_page.dart';

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
      if (!mounted) {
        return;
      }
      _showSnackBar(AppStrings.t('auth_otp_sent'));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AuthOtpPage(
            email: emailController.text.trim(),
            flow: AuthOtpFlow.recovery,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showSnackBar(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
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
    final appColors = context.authColors;
    final colorScheme = theme.colorScheme;

    return AuthPageShell(
      appBar: AppBar(
        title: Text(
          AppStrings.t("recover_access"),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.authTitleColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: context.authTitleColor,
        elevation: 0,
        centerTitle: true,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.authPrimaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 70,
              color: context.authPrimaryColor,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            AppStrings.t("forgot_title"),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.authTitleColor,
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
                      style: context.authPrimaryButtonTextStyle),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.t("back_to_login"),
              style: TextStyle(
                  color: context.authInteractiveColor,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
