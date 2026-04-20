import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_strings.dart';
import '../../data/services/animal_reference_catalog_service.dart';
import '../../domain/entities/animal_entity.dart';
import '../../shared/age_label_formatter.dart';
import '../providers/animal_reference_catalog_provider.dart';

class AnimalCard extends ConsumerWidget {
  final AnimalEntity animalData;
  final VoidCallback onTap;

  const AnimalCard({
    super.key,
    required this.animalData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final breedChoices =
        ref.watch(animalBreedChoicesProvider).valueOrNull ?? const [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.large,
          vertical: AppSizes.small,
        ),
        decoration: BoxDecoration(
          color: isDark ? appColors.cardDark : colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          boxShadow: [
            BoxShadow(
              color: appColors.lightShadow,
              blurRadius: AppSizes.medium,
              offset: const Offset(0, AppSizes.xSmall),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(
                    left: Radius.circular(AppSizes.cardRadius),
                  ),
              child: animalData.profileImageUrl != null &&
                      animalData.profileImageUrl!.isNotEmpty
                  ? Image.network(
                      animalData.profileImageUrl!,
                      width: AppSizes.animalCardImageSize,
                      height: AppSizes.animalCardImageSize,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.medium,
                  vertical: AppSizes.medium,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      animalData.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionTitle(Theme.of(context)).copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? appColors.onSolid : appColors.subduedForeground,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xSmall),
                    Text(
                      AnimalReferenceCatalogService.resolveBreedLabel(
                        animalData.breed,
                        choices: breedChoices,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(
                        Theme.of(context),
                        appColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: AppSizes.small),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildChip(
                          context,
                          Icons.cake,
                          animalData.ageLabel.isNotEmpty
                              ? animalData.ageLabel
                              : AgeLabelFormatter.format(animalData.age),
                        ),
                        if (animalData.weight != null)
                          _buildChip(
                            context,
                            Icons.monitor_weight,
                            '${animalData.weight} ${AppStrings.t('kg')}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                Icons.arrow_forward_ios,
                size: AppIconSizes.small,
                color: appColors.inputBorderLight,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppDurations.medium).slideX(begin: 0.05);
  }

  Widget _buildChip(BuildContext context, IconData icon, String label) {
    final appColors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: appColors.selectionBackground,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSizes.small, color: appColors.chipForeground),
          const SizedBox(width: AppSizes.xSmall),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(
                Theme.of(context),
                appColors.chipForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Image.asset(
      AppStrings.t('animal_default_image'),
      width: AppSizes.animalCardImageSize,
      height: AppSizes.animalCardImageSize,
      fit: BoxFit.cover,
    );
  }
}
