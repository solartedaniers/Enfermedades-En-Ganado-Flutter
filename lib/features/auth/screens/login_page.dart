import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import '../../auth/home/screens/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../profile/presentation/providers/profile_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService authService = AuthService();

  bool loading = false;
  bool showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackBar(AppStrings.t("enter_email_password"));
      return;
    }
    setState(() => loading = true);
    try {
      await authService.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final user = Supabase.instance.client.auth.currentUser;
      if (user?.emailConfirmedAt == null) {
        throw Exception(AppStrings.t("confirm_email_first"));
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
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
    // Escucha el provider para que el tema se aplique
    ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen = AppTheme.primaryColor;
    final darkGreen = const Color(0xFF1B4332);
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF1F8F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/images/logo.webp',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: primaryGreen.withValues(alpha: 0.2)),
                    ),
                    child: Icon(Icons.pets, size: 60, color: primaryGreen),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.t("app_name"),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : darkGreen,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  AppStrings.t("app_subtitle"),
                  style: const TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 40),
                _buildField(
                  controller: emailController,
                  label: AppStrings.t("email"),
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  primaryGreen: primaryGreen,
                ),
                const SizedBox(height: 20),
                _buildField(
                  controller: passwordController,
                  label: AppStrings.t("password"),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage()),
                    ),
                    child: Text(
                      AppStrings.t("forgot_password"),
                      style: TextStyle(
                          color: primaryGreen, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(AppStrings.t("login"),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppStrings.t("no_account")),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterPage()),
                      ),
                      child: Text(
                        AppStrings.t("register_here"),
                        style: TextStyle(
                            color: darkGreen, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
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
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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