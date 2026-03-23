import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen = AppTheme.primaryColor;
    final darkGreen = const Color(0xFF1B4332);
    final bgColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF1F8F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(AppStrings.t("recover_access"),
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
                  child: Icon(Icons.mark_email_read_outlined,
                      size: 70, color: primaryGreen),
                ),
                const SizedBox(height: 32),
                Text(
                  AppStrings.t("forgot_title"),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : darkGreen),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.t("forgot_subtitle"),
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: AppStrings.t("email"),
                    prefixIcon:
                        Icon(Icons.email_outlined, color: primaryGreen),
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFDEE2E6)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: primaryGreen, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: loading ? null : reset,
                    child: loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
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
                        color: isDark ? Colors.greenAccent : darkGreen,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}