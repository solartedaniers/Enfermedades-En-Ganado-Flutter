import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';

class AnimalSelectorField extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;

  const AnimalSelectorField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final hasValue = value != null && value!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.medium,
          vertical: AppSizes.large,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: appColors.inputBorderLight),
          borderRadius: BorderRadius.circular(AppSizes.small),
        ),
        child: Row(
          children: [
            Icon(icon, color: appColors.chipForeground),
            const SizedBox(width: AppSizes.medium),
            Expanded(
              child: Text(
                hasValue ? value! : label,
                style: AppTextStyles.sectionTitle(Theme.of(context)).copyWith(
                  color: hasValue ? null : appColors.mutedForeground,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: appColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
