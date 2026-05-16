import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/livestock_icon.dart';
import '../../data/services/animal_reference_catalog_service.dart';
import '../../domain/entities/animal_entity.dart';
import '../../shared/age_label_formatter.dart';
import '../providers/animal_reference_catalog_provider.dart';

/// Widget de modo lectura para el detalle de un animal.
/// Responsabilidad única: mostrar la información del animal de forma no editable.
class AnimalDetailViewMode extends ConsumerWidget {
  final AnimalEntity animal;
  final VoidCallback onMedicalHistoryTap;

  const AnimalDetailViewMode({
    super.key,
    required this.animal,
    required this.onMedicalHistoryTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breedChoices =
        ref.watch(animalBreedChoicesProvider).valueOrNull ?? const [];

    final weightText = animal.weight != null
        ? '${animal.weight} ${AppStrings.t('kg')}'
        : AppStrings.t('weight_no_data');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          icon: null,
          label: AppStrings.t('breed_label'),
          value: AnimalReferenceCatalogService.resolveBreedLabel(
            animal.breed,
            choices: breedChoices,
          ),
        ),
        _InfoRow(
          icon: Icons.cake,
          label: AppStrings.t('age_label'),
          value: animal.ageLabel.isNotEmpty
              ? animal.ageLabel
              : AgeLabelFormatter.format(animal.age),
        ),
        _InfoRow(
          icon: Icons.monitor_weight_outlined,
          label: AppStrings.t('weight_label'),
          value: weightText,
        ),
        if (animal.temperature != null)
          _InfoRow(
            icon: Icons.thermostat,
            label: AppStrings.t('temperature_label'),
            value: '${animal.temperature} \u00B0C',
          ),
        const SizedBox(height: AppSizes.xxLarge),
        SizedBox(
          width: double.infinity,
          height: AppSizes.largeButtonHeight,
          child: ElevatedButton.icon(
            onPressed: onMedicalHistoryTap,
            icon: const Icon(Icons.medical_services),
            label: Text(AppStrings.t('view_medical_history')),
          ),
        ),
      ],
    );
  }
}

/// Fila de información de un campo del detalle del animal.
class _InfoRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sectionSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Icon(icon, color: appColors.chipForeground, size: AppIconSizes.large)
          else
            const LivestockIcon(
              size: AppIconSizes.large,
              padding: EdgeInsets.only(top: 2),
            ),
          const SizedBox(width: AppSizes.small + 2),
          Text(
            '$label: ',
            style: AppTextStyles.sectionTitle(Theme.of(context)),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
