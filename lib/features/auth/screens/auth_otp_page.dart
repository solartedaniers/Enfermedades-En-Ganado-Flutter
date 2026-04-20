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
  final _authService = AuthService();
  late final List<TextEditingController> _digitControllers;
  late final List<FocusNode> _digitFocusNodes;

  Timer? _countdownTimer;
  bool _isVerifying = false;
  bool _isResending = false;
  int _remainingSeconds = AuthOtpConstants.expirationSeconds;

  @override
  void initState() {
    super.initState();
    _digitControllers = List.generate(
      AuthOtpConstants.codeLength,
      (_) => TextEditingController(),
    );
    _digitFocusNodes = List.generate(
      AuthOtpConstants.codeLength,
      (_) => FocusNode(),
    );
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final controller in _digitControllers) {
      controller.dispose();
    }
    for (final focusNode in _digitFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _enteredCode {
    return _digitControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyCode() async {
    final code = _enteredCode.trim();
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

      _clearCode();
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

  void _clearCode() {
    for (final controller in _digitControllers) {
      controller.clear();
    }
    if (_digitFocusNodes.isNotEmpty) {
      _digitFocusNodes.first.requestFocus();
    }
    setState(() {});
  }

  void _handleDigitChanged(int index, String value) {
    if (value.isEmpty) {
      setState(() {});
      return;
    }

    final digit = value.substring(value.length - 1);
    _digitControllers[index].value = TextEditingValue(
      text: digit,
      selection: TextSelection.collapsed(offset: digit.length),
    );

    if (index < AuthOtpConstants.codeLength - 1) {
      _digitFocusNodes[index + 1].requestFocus();
    } else {
      _digitFocusNodes[index].unfocus();
    }

    setState(() {});
  }

  void _handleBackspace(int index, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace) {
      return;
    }

    if (_digitControllers[index].text.isNotEmpty) {
      _digitControllers[index].clear();
      setState(() {});
      return;
    }

    if (index == 0) {
      return;
    }

    _digitControllers[index - 1].clear();
    _digitFocusNodes[index - 1].requestFocus();
    setState(() {});
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
          _OtpCodeBoxes(
            controllers: _digitControllers,
            focusNodes: _digitFocusNodes,
            isDark: isDark,
            onChanged: _handleDigitChanged,
            onCompleted: _verifyCode,
            onBackspace: _handleBackspace,
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

class _OtpCodeBoxes extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool isDark;
  final void Function(int index, String value) onChanged;
  final VoidCallback onCompleted;
  final void Function(int index, KeyEvent event) onBackspace;

  const _OtpCodeBoxes({
    required this.controllers,
    required this.focusNodes,
    required this.isDark,
    required this.onChanged,
    required this.onCompleted,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = context.authColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final totalSpacing = spacing * (AuthOtpConstants.codeLength - 1);
        final boxWidth = ((constraints.maxWidth - totalSpacing) /
                AuthOtpConstants.codeLength)
            .clamp(44.0, 56.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(AuthOtpConstants.codeLength, (index) {
            final hasValue = controllers[index].text.isNotEmpty;
            final isActive = focusNodes[index].hasFocus;

            return Padding(
              padding: EdgeInsets.only(
                right: index == AuthOtpConstants.codeLength - 1 ? 0 : spacing,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: boxWidth,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? appColors.inputFillDark : colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive
                        ? context.authPrimaryColor
                        : colorScheme.outlineVariant,
                    width: isActive ? 1.8 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hasValue
                          ? context.authPrimaryColor.withValues(alpha: 0.12)
                          : appColors.lightShadow,
                      blurRadius: hasValue ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Focus(
                  onKeyEvent: (_, event) {
                    onBackspace(index, event);
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    autofocus: index == 0,
                    keyboardType: TextInputType.number,
                    textInputAction: index == AuthOtpConstants.codeLength - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.authTitleColor,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) => onChanged(index, value),
                    onSubmitted: (_) {
                      if (index == AuthOtpConstants.codeLength - 1) {
                        onCompleted();
                      }
                    },
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
