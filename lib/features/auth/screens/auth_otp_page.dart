import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_strings.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../constants/auth_otp_constants.dart';
import '../models/auth_otp_flow.dart';
import '../services/auth_service.dart';
import '../widgets/auth_page_shell.dart';
import '../widgets/auth_ui.dart';
import '../../auth/home/screens/home_page.dart';
import 'login_page.dart';
import 'reset_password_page.dart';

class AuthOtpPage extends ConsumerStatefulWidget {
  final String email;
  final AuthOtpFlow flow;
  final String? password;

  const AuthOtpPage({
    super.key,
    required this.email,
    required this.flow,
    this.password,
  });

  @override
  ConsumerState<AuthOtpPage> createState() => _AuthOtpPageState();
}

class _AuthOtpPageState extends ConsumerState<AuthOtpPage> {
  final _codeController = TextEditingController();
  final _authService = AuthService();

  Timer? _countdownTimer;
  bool _isVerifying = false;
  bool _isResending = false;
  int _remainingSeconds = AuthOtpConstants.expirationSeconds;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != AuthOtpConstants.codeLength) {
      _showSnackBar(AppStrings.t('auth_otp_invalid_length'));
      return;
    }

    setState(() => _isVerifying = true);

    try {
      switch (widget.flow) {
        case AuthOtpFlow.signup:
          await _authService.verifySignUpOtp(
            email: widget.email,
            token: code,
          );
          await ref.read(profileProvider.notifier).reload();
          if (widget.password != null && widget.password!.isNotEmpty) {
            await ref.read(profileProvider.notifier).cacheOfflineAccess(
                  email: widget.email,
                  password: widget.password!,
                );
          }
          if (!mounted) {
            return;
          }
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
          break;
        case AuthOtpFlow.recovery:
          await _authService.verifyRecoveryOtp(
            email: widget.email,
            token: code,
          );
          if (!mounted) {
            return;
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
          );
          break;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendCode() async {
    if (_remainingSeconds > 0) {
      return;
    }

    setState(() => _isResending = true);

    try {
      switch (widget.flow) {
        case AuthOtpFlow.signup:
          await _authService.resendSignUpOtp(widget.email);
          break;
        case AuthOtpFlow.recovery:
          await _authService.resetPassword(widget.email);
          break;
      }

      _codeController.clear();
      _startCountdown();

      if (!mounted) {
        return;
      }

      _showSnackBar(AppStrings.t('auth_otp_resent'));
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(error.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _remainingSeconds = AuthOtpConstants.expirationSeconds);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        return;
      }

      setState(() => _remainingSeconds -= 1);
    });
  }

  String _formatRemainingTime() {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _titleKey() {
    switch (widget.flow) {
      case AuthOtpFlow.signup:
        return 'auth_otp_signup_title';
      case AuthOtpFlow.recovery:
        return 'auth_otp_recovery_title';
    }
  }

  String _subtitleKey() {
    switch (widget.flow) {
      case AuthOtpFlow.signup:
        return 'auth_otp_signup_subtitle';
      case AuthOtpFlow.recovery:
        return 'auth_otp_recovery_subtitle';
    }
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
    final appColors = context.authColors;
    final isDark = theme.brightness == Brightness.dark;

    return AuthPageShell(
      appBar: AppBar(
        title: Text(
          AppStrings.t('auth_otp_page_title'),
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
              Icons.pin_outlined,
              size: 68,
              color: context.authPrimaryColor,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            AppStrings.t(_titleKey()),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.authTitleColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.t(_subtitleKey()).replaceFirst('{email}', widget.email),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: appColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            textAlign: TextAlign.center,
            maxLength: AuthOtpConstants.codeLength,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(AuthOtpConstants.codeLength),
            ],
            onSubmitted: (_) => _verifyCode(),
            decoration: InputDecoration(
              labelText: AppStrings.t('auth_otp_code_label'),
              hintText: AppStrings.t('auth_otp_code_hint'),
              prefixIcon: Icon(
                Icons.password_rounded,
                color: appColors.chipForeground,
              ),
              counterText: '',
              filled: true,
              fillColor: isDark
                  ? appColors.inputFillDark
                  : colorScheme.surface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _remainingSeconds > 0
                ? AppStrings.t('auth_otp_expires_in')
                    .replaceFirst('{time}', _formatRemainingTime())
                : AppStrings.t('auth_otp_expired'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _remainingSeconds > 0
                  ? appColors.mutedForeground
                  : appColors.danger,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _verifyCode,
              child: _isVerifying
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      AppStrings.t('auth_otp_verify_button'),
                      style: context.authPrimaryButtonTextStyle,
                    ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _isResending || _remainingSeconds > 0 ? null : _resendCode,
            child: _isResending
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: isDark ? appColors.accent : appColors.heroGradientStart,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    AppStrings.t('auth_otp_resend_button'),
                    style: TextStyle(
                      color: context.authInteractiveColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: Text(
              AppStrings.t('back_to_login'),
              style: TextStyle(
                color: appColors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
