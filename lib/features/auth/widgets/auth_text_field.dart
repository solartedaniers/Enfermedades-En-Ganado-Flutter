import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: appColors.chipForeground),
        labelStyle: TextStyle(color: appColors.mutedForeground),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? appColors.inputFillDark
            : Theme.of(context).colorScheme.surface,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
