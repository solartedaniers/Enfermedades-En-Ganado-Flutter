import 'package:flutter/material.dart';

import '../../../../../core/theme/app_durations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_sizes.dart';

class ProfileSelectTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ProfileSelectTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.small + 2),
      child: AnimatedContainer(
        duration: AppDurations.short,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(AppSizes.small + 2),
          border: Border.all(
            color: selected
                ? appColors.chipForeground.withValues(alpha: 0.35)
                : (isDark
                    ? appColors.inputBorderDark
                    : appColors.inputBorderLight.withValues(alpha: 0.7)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? appColors.chipForeground : appColors.mutedForeground,
              size: AppIconSizes.large,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: AppIconSizes.medium, color: appColors.mutedForeground),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected
                    ? appColors.chipForeground
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
