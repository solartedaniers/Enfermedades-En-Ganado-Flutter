import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String roleLabel;
  final String? avatarUrl;
  final bool isUploadingAvatar;
  final VoidCallback onAvatarTap;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.roleLabel,
    required this.avatarUrl,
    required this.isUploadingAvatar,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
      decoration: BoxDecoration(
        color: isDark ? appColors.cardDark : colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        border: Border.all(
          color: appColors.chipForeground.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: appColors.lightShadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: appColors.chipForeground, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: appColors.darkShadow.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: AppSizes.profileAvatarRadius,
                    backgroundColor: appColors.whiteOverlay,
                    backgroundImage:
                        avatarUrl != null && avatarUrl!.isNotEmpty
                            ? NetworkImage(avatarUrl!)
                            : null,
                    child: avatarUrl == null || avatarUrl!.isEmpty
                        ? Icon(
                            Icons.person,
                            size: AppIconSizes.xxLarge,
                            color: appColors.chipForeground,
                          )
                        : null,
                  ),
                ),
                if (isUploadingAvatar)
                  CircularProgressIndicator(color: appColors.chipForeground)
                else
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isDark ? appColors.cardDark : colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: appColors.chipForeground.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: AppIconSizes.medium,
                      color: appColors.chipForeground,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.medium),
          Text(
            name,
            style: AppTextStyles.sectionTitle(theme).copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(AppSizes.chipRadius),
              border: Border.all(
                color: appColors.chipForeground.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              roleLabel,
              style: TextStyle(
                color: appColors.chipForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
