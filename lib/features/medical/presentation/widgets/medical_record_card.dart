import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/app_date_formatter.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../domain/entities/medical_record_entity.dart';
import '../../../animals/presentation/widgets/animal_profile_image.dart';

class MedicalRecordCard extends StatelessWidget {
  final MedicalRecordEntity record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicalRecordCard({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.medium),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: AppIconSizes.small,
                  color: appColors.mutedForeground,
                ),
                const SizedBox(width: AppSizes.xSmall),
                Text(
                  AppDateFormatter.shortDate(record.createdAt),
                  style: AppTextStyles.caption(theme, appColors.mutedForeground),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    size: AppIconSizes.medium,
                    color: appColors.chipForeground,
                  ),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    size: AppIconSizes.medium,
                    color: appColors.danger,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
            if (record.imageUrl != null && record.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.small),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.small),
                child: AnimalProfileImage(
                  networkImageUrl: record.imageUrl,
                  height: AppSizes.medicalRecordImageHeight,
                  width: double.infinity,
                ),
              ),
            ],
            const SizedBox(height: AppSizes.small),
            Text(
              '${AppStrings.t("diagnosis_label")}:',
              style: AppTextStyles.emphasisLabel(
                theme,
                theme.colorScheme.onSurface,
              ),
            ),
            Text(record.diagnosis ?? AppStrings.t('no_diagnosis')),
            const SizedBox(height: AppSizes.small),
            Text(
              '${AppStrings.t("ai_result")}:',
              style: AppTextStyles.emphasisLabel(
                theme,
                theme.colorScheme.onSurface,
              ),
            ),
            Text(record.aiResult ?? AppStrings.t('no_ai_result')),
          ],
        ),
      ),
    );
  }
}
