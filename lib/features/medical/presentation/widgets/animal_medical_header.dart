import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/widgets/livestock_icon.dart';
import '../../../animals/domain/constants/animal_breed_catalog.dart';
import '../../../animals/domain/entities/animal_entity.dart';
import '../../../animals/shared/age_label_formatter.dart';

class AnimalMedicalHeader extends StatelessWidget {
  final AnimalEntity animal;
  final VoidCallback onAvatarTap;

  const AnimalMedicalHeader({
    super.key,
    required this.animal,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.xLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appColors.medicalHeaderStart, appColors.medicalHeaderEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: AppSizes.medicalAvatarRadius,
                  backgroundColor: appColors.whiteOverlay,
                  backgroundImage: animal.profileImageUrl != null &&
                          animal.profileImageUrl!.isNotEmpty
                      ? NetworkImage(animal.profileImageUrl!)
                      : null,
                  child: animal.profileImageUrl == null ||
                          animal.profileImageUrl!.isEmpty
                      ? const LivestockIcon(
                          size: AppIconSizes.xLarge,
                          padding: EdgeInsets.all(18),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.xSmall),
                    decoration: BoxDecoration(
                      color: appColors.onSolid,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: AppIconSizes.small,
                      color: appColors.chipForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.large),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animal.name,
                  style: AppTextStyles.title(
                    theme,
                  ).copyWith(color: appColors.onSolid),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.xSmall - 2),
                Text(
                  AnimalBreedCatalog.displayLabel(animal.breed),
                  style: AppTextStyles.caption(
                    theme,
                    appColors.onSolid.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppSizes.xSmall - 2),
                Text(
                  animal.ageLabel.isNotEmpty
                      ? animal.ageLabel
                      : AgeLabelFormatter.format(animal.age),
                  style: AppTextStyles.caption(
                    theme,
                    appColors.onSolid.withValues(alpha: 0.8),
                  ),
                ),
                if (animal.weight != null) ...[
                  const SizedBox(height: AppSizes.xSmall - 2),
                  Text(
                    '${animal.weight} ${AppStrings.t("kg")}',
                    style: AppTextStyles.caption(
                      theme,
                      appColors.onSolid.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
