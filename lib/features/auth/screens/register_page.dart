import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../widgets/auth_page_shell.dart';
import 'login_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final phone = TextEditingController();
  final location = TextEditingController();

  final authService = AuthService();
  final formKey = GlobalKey<FormState>();

  String? userType;
  bool loading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool hasUpper = false;
  bool hasNumber = false;
  bool hasSymbol = false;
  bool hasMinLength = false;
  bool hasMaxLength = true;

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    username.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    phone.dispose();
    location.dispose();
    super.dispose();
  }

  void checkPassword(String value) {
    setState(() {
      hasUpper = value.contains(RegExp(r'[A-Z]'));
      hasNumber = value.contains(RegExp(r'[0-9]'));
      hasSymbol = value.contains(RegExp(r'[!@#\$&*~]'));
      hasMinLength = value.length >= 8;
      hasMaxLength = value.length <= 20;
    });
  }

  bool isStrongPassword() =>
      hasUpper && hasNumber && hasSymbol && hasMinLength && hasMaxLength;

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;
    if (!isStrongPassword()) {
      _showSnackBar(AppStrings.t("password_weak"));
      return;
    }
    if (password.text != confirmPassword.text) {
      _showSnackBar(AppStrings.t("passwords_no_match"));
      return;
    }
    if (userType == null) {
      _showSnackBar(AppStrings.t("select_user_type"));
      return;
    }

    setState(() => loading = true);

    try {
      await authService.signUpUser(
        email: email.text.trim(),
        password: password.text.trim(),
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        username: username.text.trim(),
        phone: phone.text.trim(),
        location: location.text.trim(),
        userType: userType!,
      );
      if (!mounted) return;

      _showSnackBar(AppStrings.t("account_created"));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (error) {
      if (!mounted) return;

      _showSnackBar(
        error.toString().contains("over_email_send_rate_limit")
            ? AppStrings.t("wait_email")
            : error.toString().replaceAll("Exception: ", ""),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    final appColors = context.appColors;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: appColors.chipForeground),
      labelStyle: TextStyle(color: appColors.mutedForeground),
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark
          ? appColors.inputFillDark
          : Theme.of(context).colorScheme.surface,
    );
  }

  Widget _passwordRule(String text, bool valid) {
    final appColors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle : Icons.cancel_outlined,
            color: valid
                ? appColors.success
                : appColors.mutedForeground.withValues(alpha: 0.5),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: valid ? appColors.success : appColors.mutedForeground,
            ),
          ),
        ],
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
      appBar: AppBar(
        title: Text(
          AppStrings.t("create_account"),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor:
            isDark ? colorScheme.onSurface : appColors.heroGradientStart,
        elevation: 0,
        centerTitle: true,
      ),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Text(
              AppStrings.t("join_app"),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color:
                    isDark ? colorScheme.onSurface : appColors.heroGradientStart,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.t("manage_livestock"),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: appColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: firstName,
              decoration:
                  _inputStyle(AppStrings.t("first_name"), Icons.person_outline),
              validator: (value) =>
                  value!.isEmpty ? AppStrings.t("enter_name") : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: lastName,
              decoration:
                  _inputStyle(AppStrings.t("last_name"), Icons.person_outline),
              validator: (value) =>
                  value!.isEmpty ? AppStrings.t("enter_last_name") : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: username,
              decoration:
                  _inputStyle(AppStrings.t("username"), Icons.alternate_email),
              validator: (value) =>
                  value!.isEmpty ? AppStrings.t("enter_username") : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  _inputStyle(AppStrings.t("email"), Icons.email_outlined),
              validator: (value) =>
                  value!.isEmpty ? AppStrings.t("enter_email") : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: _inputStyle(
                AppStrings.t("phone"),
                Icons.phone_android_outlined,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: location,
              decoration: _inputStyle(
                AppStrings.t("location"),
                Icons.location_on_outlined,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: userType,
              items: [
                DropdownMenuItem(
                  value: "farmer",
                  child: Text(AppStrings.t("farmer")),
                ),
                DropdownMenuItem(
                  value: "veterinarian",
                  child: Text(AppStrings.t("vet")),
                ),
              ],
              onChanged: (value) => setState(() => userType = value),
              decoration:
                  _inputStyle(AppStrings.t("user_type"), Icons.badge_outlined),
              validator: (value) =>
                  value == null ? AppStrings.t("select_type") : null,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: password,
              obscureText: !showPassword,
              onChanged: checkPassword,
              decoration: _inputStyle(
                AppStrings.t("password"),
                Icons.lock_outline,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? appColors.cardDark : colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: appColors.inputBorderLight),
              ),
              child: Column(
                children: [
                  _passwordRule(AppStrings.t("min_8_chars"), hasMinLength),
                  _passwordRule(
                    AppStrings.t("upper_and_number"),
                    hasUpper && hasNumber,
                  ),
                  _passwordRule(AppStrings.t("symbol_required"), hasSymbol),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: confirmPassword,
              obscureText: !showConfirmPassword,
              decoration: _inputStyle(
                AppStrings.t("confirm_password"),
                Icons.lock_reset_outlined,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    showConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () => setState(
                    () => showConfirmPassword = !showConfirmPassword,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : register,
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
                        AppStrings.t("register_btn"),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppStrings.t("already_account")),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppStrings.t("sign_in"),
                    style: TextStyle(
                      color:
                          isDark ? appColors.accent : appColors.heroGradientStart,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
