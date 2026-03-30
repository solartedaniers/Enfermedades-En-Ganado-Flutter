import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/offline_auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../widgets/auth_page_shell.dart';
import '../widgets/auth_text_field.dart';
import '../../auth/home/screens/home_page.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../services/auth_service.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

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

    final isOnline = await ConnectivityService.isConnected();

    try {
      if (isOnline) {
        await authService.signIn(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final currentUser = Supabase.instance.client.auth.currentUser;

        if (currentUser?.emailConfirmedAt == null) {
          throw Exception(AppStrings.t("confirm_email_first"));
        }

        await OfflineAuthService.saveSession(
          userId: currentUser!.id,
          userName: currentUser.userMetadata?['username'] ??
              AppStrings.t("default_username"),
          avatarUrl: currentUser.userMetadata?['avatar_url'],
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        final hasLocalSession = await OfflineAuthService.hasSession();

        if (!mounted) return;

        if (hasLocalSession) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.t("offline_mode_login"),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: context.appColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          _showSnackBar(AppStrings.t("offline_login_first_time"));
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                AppStrings.t("app_logo_path"),
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.pets,
                    size: 60,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.t("app_name"),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? colorScheme.onSurface : appColors.heroGradientStart,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            AppStrings.t("app_subtitle"),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: appColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 40),
          AuthTextField(
            controller: emailController,
            label: AppStrings.t("email"),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          AuthTextField(
            controller: passwordController,
            label: AppStrings.t("password"),
            icon: Icons.lock_outline,
            obscureText: !showPassword,
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () => setState(() => showPassword = !showPassword),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ForgotPasswordPage(),
                ),
              ),
              child: Text(
                AppStrings.t("forgot_password"),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
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
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      AppStrings.t("login"),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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
                    builder: (_) => const RegisterPage(),
                  ),
                ),
                child: Text(
                  AppStrings.t("register_here"),
                  style: TextStyle(
                    color: appColors.heroGradientStart,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
