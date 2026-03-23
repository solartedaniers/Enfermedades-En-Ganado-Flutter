import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../profile/presentation/providers/profile_provider.dart';

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

  String? userType;
  final authService = AuthService();
  final formKey = GlobalKey<FormState>();

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
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().contains("over_email_send_rate_limit")
          ? AppStrings.t("wait_email")
          : e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    final primaryGreen = AppTheme.primaryColor;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryGreen),
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
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
    );
  }

  Widget _passwordRule(String text, bool valid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle : Icons.cancel_outlined,
            color: valid ? Colors.green : Colors.grey.withValues(alpha: 0.5),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: valid ? Colors.green : Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final darkGreen = const Color(0xFF1B4332);
    final bgColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF1F8F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(AppStrings.t("create_account"),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : darkGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Text(AppStrings.t("join_app"),
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : darkGreen)),
              const SizedBox(height: 8),
              Text(AppStrings.t("manage_livestock"),
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 30),
              TextFormField(
                controller: firstName,
                decoration:
                    _inputStyle(AppStrings.t("first_name"), Icons.person_outline),
                validator: (v) =>
                    v!.isEmpty ? AppStrings.t("enter_name") : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: lastName,
                decoration:
                    _inputStyle(AppStrings.t("last_name"), Icons.person_outline),
                validator: (v) =>
                    v!.isEmpty ? AppStrings.t("enter_last_name") : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: username,
                decoration: _inputStyle(
                    AppStrings.t("username"), Icons.alternate_email),
                validator: (v) =>
                    v!.isEmpty ? AppStrings.t("enter_username") : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputStyle(
                    AppStrings.t("email"), Icons.email_outlined),
                validator: (v) =>
                    v!.isEmpty ? AppStrings.t("enter_email") : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: _inputStyle(
                    AppStrings.t("phone"), Icons.phone_android_outlined),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: location,
                decoration: _inputStyle(
                    AppStrings.t("location"), Icons.location_on_outlined),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: userType,
                items: [
                  DropdownMenuItem(
                      value: "ganadero",
                      child: Text(AppStrings.t("farmer"))),
                  DropdownMenuItem(
                      value: "veterinario",
                      child: Text(AppStrings.t("vet"))),
                ],
                onChanged: (v) => setState(() => userType = v),
                decoration: _inputStyle(
                    AppStrings.t("user_type"), Icons.badge_outlined),
                validator: (v) =>
                    v == null ? AppStrings.t("select_type") : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: password,
                obscureText: !showPassword,
                onChanged: checkPassword,
                decoration:
                    _inputStyle(AppStrings.t("password"), Icons.lock_outline)
                        .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(showPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => showPassword = !showPassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDEE2E6)),
                ),
                child: Column(
                  children: [
                    _passwordRule(
                        AppStrings.t("min_8_chars"), hasMinLength),
                    _passwordRule(AppStrings.t("upper_and_number"),
                        hasUpper && hasNumber),
                    _passwordRule(
                        AppStrings.t("symbol_required"), hasSymbol),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPassword,
                obscureText: !showConfirmPassword,
                decoration: _inputStyle(AppStrings.t("confirm_password"),
                        Icons.lock_reset_outlined)
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(showConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () => setState(
                        () => showConfirmPassword = !showConfirmPassword),
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
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(AppStrings.t("register_btn"),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.1)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppStrings.t("already_account")),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppStrings.t("sign_in"),
                        style: TextStyle(
                            color: isDark ? Colors.greenAccent : darkGreen,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}