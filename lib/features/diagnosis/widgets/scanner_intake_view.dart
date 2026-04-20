import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_strings.dart';
import '../../../geolocation/presentation/providers/geolocation_provider.dart';
import '../../animals/domain/constants/animal_breed_catalog.dart';
import '../../animals/domain/entities/animal_entity.dart';
import '../../animals/presentation/pages/add_animal_page.dart';

class ScannerIntakeView extends StatelessWidget {
  final Future<List<AnimalEntity>> animalsFuture;
  final AnimalEntity? selectedAnimal;
  final TextEditingController mainReasonController;
  final TextEditingController symptomsController;
  final TextEditingController temperatureController;
  final Uint8List? capturedImageBytes;
  final bool isSubmitting;
  final String? errorMessage;
  final AsyncValue<dynamic> geolocationState;
  final ValueChanged<AnimalEntity> onAnimalSelected;
  final VoidCallback onOpenCamera;
  final VoidCallback onDiagnoseWithoutImage;

  const ScannerIntakeView({
    super.key,
    required this.animalsFuture,
    required this.selectedAnimal,
    required this.mainReasonController,
    required this.symptomsController,
    required this.temperatureController,
    required this.capturedImageBytes,
    required this.isSubmitting,
    required this.errorMessage,
    required this.geolocationState,
    required this.onAnimalSelected,
    required this.onOpenCamera,
    required this.onDiagnoseWithoutImage,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AnimalEntity>>(
      future: animalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xxLarge),
              child: Text(
                '${AppStrings.t('diagnosis_load_animals_error')}: ${snapshot.error}',
              ),
            ),
          );
        }

        final animals = snapshot.data ?? [];
        if (animals.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xxLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pets_outlined,
                    size: AppIconSizes.xxxLarge,
                    color: context.appColors.mutedForeground,
                  ),
                  const SizedBox(height: AppSizes.large),
                  Text(
                    AppStrings.t('diagnosis_register_animal_first'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.large),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddAnimalPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appColors.scannerAccent,
                      foregroundColor: context.appColors.onSolid,
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(AppStrings.t('register_animal')),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.xLarge),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSizes.xxLarge),
                boxShadow: [
                  BoxShadow(
                    color: context.appColors.scannerAccent.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.t('diagnosis_real_title'),
                    style: AppTextStyles.title(Theme.of(context)),
                  ),
                  const SizedBox(height: AppSizes.small + 2),
                  Text(
                    AppStrings.t('diagnosis_real_subtitle'),
                    style: AppTextStyles.bodyMuted(
                      Theme.of(context),
                      context.appColors.subduedForeground,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xLarge),
                  _ScannerGeolocationCard(geolocationState: geolocationState),
                  const SizedBox(height: AppSizes.large),
                  DropdownButtonFormField<String>(
                    initialValue: selectedAnimal?.id,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('diagnosis_animal_label'),
                    ),
                    items: animals
                        .map(
                          (animal) => DropdownMenuItem<String>(
                            value: animal.id,
                            child: Text(
                              '${animal.name} \u2022 ${AnimalBreedCatalog.displayLabel(animal.breed)}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      onAnimalSelected(
                        animals.firstWhere((item) => item.id == value),
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.large),
                  TextField(
                    controller: mainReasonController,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('diagnosis_main_reason'),
                      hintText: AppStrings.t('diagnosis_main_reason_hint'),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSizes.large),
                  TextField(
                    controller: symptomsController,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('diagnosis_symptoms_label'),
                      hintText: AppStrings.t('diagnosis_symptoms_hint'),
                    ),
                    minLines: 4,
                    maxLines: 6,
                  ),
                  const SizedBox(height: AppSizes.large),
                  TextField(
                    controller: temperatureController,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('diagnosis_temperature_label'),
                      hintText: AppStrings.t('diagnosis_temperature_hint'),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: AppSizes.large),
                  if (capturedImageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
                      child: Image.memory(
                        capturedImageBytes!,
                        height: AppSizes.diagnosisPreviewImageHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: AppSizes.large),
                   Row(
                     children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onOpenCamera,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.appColors.scannerAccent,
                            side: BorderSide(
                              color: context.appColors.scannerAccent,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.sectionSpacing,
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            capturedImageBytes == null
                                ? AppStrings.t('diagnosis_add_photo')
                                : AppStrings.t('change_photo'),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.medium),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting ? null : onDiagnoseWithoutImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.appColors.scannerAccent,
                            foregroundColor: context.appColors.onSolid,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.sectionSpacing,
                            ),
                          ),
                          icon: isSubmitting
                              ? SizedBox(
                                  width: AppIconSizes.medium,
                                  height: AppIconSizes.medium,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                          context.appColors.onSolid,
                                        ),
                                  ),
                                )
                              : const Icon(Icons.psychology_alt_outlined),
                          label: Text(AppStrings.t('diagnosis_analyze')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.medium),
                  Text(
                    AppStrings.t('diagnosis_camera_optional'),
                    style: AppTextStyles.bodyMuted(
                      Theme.of(context),
                      context.appColors.subduedForeground,
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: AppSizes.large),
                    Text(
                      errorMessage!,
                      style: AppTextStyles.bodyMuted(
                        Theme.of(context),
                        context.appColors.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScannerGeolocationCard extends ConsumerWidget {
  final AsyncValue<dynamic> geolocationState;

  const _ScannerGeolocationCard({required this.geolocationState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppSizes.sectionSpacing),
      decoration: BoxDecoration(
        color: appColors.selectionBackground,
        borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, color: appColors.chipForeground),
          const SizedBox(width: AppSizes.medium),
          Expanded(
            child: geolocationState.when(
              data: (contextValue) {
                if (contextValue == null) {
                  return Text(AppStrings.t('geolocation_unavailable'));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t('geolocation_region_ready'),
                      style: AppTextStyles.bodyStrong(
                        Theme.of(context),
                        Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xSmall),
                    Text(
                      '${AppStrings.t('geolocation_region_label')}: ${contextValue.regionLabel}',
                    ),
                    const SizedBox(height: AppSizes.xSmall - 2),
                    Text(
                      '${AppStrings.t('geolocation_climate_label')}: ${contextValue.climateZone}',
                    ),
                  ],
                );
              },
              loading: () => Text(AppStrings.t('geolocation_loading')),
              error: (error, _) => Text(
                '${AppStrings.t('geolocation_unavailable')}: $error',
                style: AppTextStyles.bodyMuted(
                  Theme.of(context),
                  appColors.danger,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref
                .read(currentGeolocationContextProvider.notifier)
                .loadCurrentContext(),
            tooltip: AppStrings.t('geolocation_refresh'),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
