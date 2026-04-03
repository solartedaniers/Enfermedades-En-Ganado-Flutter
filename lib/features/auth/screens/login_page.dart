import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_json_keys.dart';
import '../../../../core/constants/app_user_type.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../profile/presentation/providers/managed_client_provider.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../widgets/auth_preferences_button.dart';
import '../widgets/auth_page_shell.dart';
import '../widgets/auth_text_field.dart';
import '../../auth/home/screens/home_page.dart';
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
      _showSnackBar(AppStrings.t('enter_email_password'));
      return;
    }

    setState(() => loading = true);

    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      final isConnected = !connectivityResults.contains(ConnectivityResult.none);

      if (isConnected) {
        await authService.signIn(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser?.emailConfirmedAt == null) {
          throw Exception(AppStrings.t('confirm_email_first'));
        }

        await ref.read(profileProvider.notifier).reload();
        await ref.read(profileProvider.notifier).cacheOfflineAccess(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );
        await _importPendingVeterinarianClient(currentUser!);
      } else {
        final authenticated = await ref
            .read(profileProvider.notifier)
            .activateOfflineSession(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );

        if (!authenticated) {
          throw Exception(AppStrings.t('offline_login_first_time'));
        }
      }

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(error.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _importPendingVeterinarianClient(User currentUser) async {
    final userType = AppUserTypeCodec.fromValue(
      currentUser.userMetadata?[AppJsonKeys.userType] as String?,
    );
    if (!userType.isVeterinarian) {
      return;
    }

    final managedClientService = ref.read(managedClientServiceProvider);
    final pendingDraft = await managedClientService.consumePendingDraft(
      emailController.text.trim(),
    );

    if (pendingDraft == null) {
      return;
    }

    final snapshot = await managedClientService.loadSnapshot(currentUser.id);
    if (snapshot.clients.isNotEmpty) {
      return;
    }

    await ref.read(managedClientProvider.notifier).createClient(
          name: pendingDraft.name,
          location: pendingDraft.location,
        );
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
      appBar: AppBar(
        leading: const AuthPreferencesButton(),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
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
                  color: appColors.lightShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                AppStrings.t('app_logo_path'),
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
          const SizedBox(height: 40),
          AuthTextField(
            controller: emailController,
            label: AppStrings.t('email'),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          AuthTextField(
            controller: passwordController,
            label: AppStrings.t('password'),
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
                AppStrings.t('forgot_password'),
                style: TextStyle(
                  color: isDark ? appColors.accent : appColors.heroGradientStart,
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
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      AppStrings.t('login'),
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
              Text(AppStrings.t('no_account')),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterPage(),
                  ),
                ),
                child: Text(
                  AppStrings.t('register_here'),
                  style: TextStyle(
                    color: isDark ? appColors.accent : appColors.heroGradientStart,
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
