import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AuthPageShell extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const AuthPageShell({
    super.key,
    required this.child,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? appColors.authBackgroundDark
          : appColors.authBackgroundLight,
      appBar: appBar,
      body: SafeArea(
        top: appBar == null,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }
}
