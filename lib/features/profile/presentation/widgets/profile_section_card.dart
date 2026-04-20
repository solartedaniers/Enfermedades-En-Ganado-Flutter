import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';

class ProfileSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? appColors.cardDark : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: appColors.lightShadow,
            blurRadius: AppSizes.medium,
            offset: const Offset(0, AppSizes.xSmall),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: appColors.chipForeground, size: AppSizes.xLarge),
                const SizedBox(width: AppSizes.small),
                Text(
                  title,
                  style: AppTextStyles.sectionTitle(Theme.of(context)),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.small),
            ...children,
          ],
        ),
      ),
    );
  }
}
