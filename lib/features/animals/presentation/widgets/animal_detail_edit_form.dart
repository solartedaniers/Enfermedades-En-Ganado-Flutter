import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/livestock_icon.dart';
import '../../data/services/animal_reference_catalog_service.dart';
import '../../shared/animal_input_formatters.dart';
import '../controllers/animal_form_controller.dart';
import '../providers/animal_reference_catalog_provider.dart';
import 'animal_selector_field.dart';

/// Formulario de edición del detalle de un animal.
/// Responsabilidad única: mostrar los campos editables del animal.
class AnimalDetailEditForm extends ConsumerWidget {
  final AnimalFormController formController;
  final VoidCallback onBreedTap;
  final VoidCallback onAgeTap;

  const AnimalDetailEditForm({
    super.key,
    required this.formController,
    required this.onBreedTap,
    required this.onAgeTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;
    final breedChoices =
        ref.watch(animalBreedChoicesProvider).valueOrNull ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: formController.nameController,
          inputFormatters: [AnimalInputFormatters.name],
          decoration: InputDecoration(
            labelText: '${AppStrings.t('name')} *',
            prefixIcon: const LivestockIcon(padding: EdgeInsets.all(12)),
          ),
        ),
        const SizedBox(height: AppSizes.sectionSpacing),
        AnimalSelectorField(
          label: AppStrings.t('breed_label'),
          value: formController.selectedBreedKey == null
              ? null
              : AnimalReferenceCatalogService.resolveBreedLabel(
                  formController.selectedBreedKey,
                  choices: breedChoices,
                ),
          icon: Icons.category_outlined,
          onTap: onBreedTap,
        ),
        const SizedBox(height: AppSizes.sectionSpacing),
        AnimalSelectorField(
          label: AppStrings.t('age_label'),
          value: formController.selectedAgeOption?.label,
          icon: Icons.cake_outlined,
          onTap: onAgeTap,
        ),
        const SizedBox(height: AppSizes.sectionSpacing),
        TextFormField(
          controller: formController.weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [AnimalInputFormatters.decimal],
          decoration: InputDecoration(
            labelText:
                '${AppStrings.t('weight')} - ${AppStrings.t('optional')}',
            hintText: AppStrings.t('weight_hint'),
            prefixIcon: Icon(
              Icons.monitor_weight_outlined,
              color: appColors.chipForeground,
            ),
            suffixText: AppStrings.t('kg'),
          ),
        ),
        const SizedBox(height: AppSizes.formBottomSpacing),
      ],
    );
  }
}
