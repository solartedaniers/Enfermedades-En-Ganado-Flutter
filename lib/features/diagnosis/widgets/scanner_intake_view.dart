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

class ScannerIntakeView extends StatelessWidget {
  final Future<List<AnimalEntity>> animalsFuture;
  final AnimalEntity? selectedAnimal;
  final TextEditingController mainReasonController;
  final TextEditingController symptomsController;
  final TextEditingController temperatureController;
  final List<Uint8List> capturedImages;
  final int maxImages;
  final bool isSubmitting;
  final String? errorMessage;
  final AsyncValue<bool> connectivityState;
  final AsyncValue<dynamic> geolocationState;
  final ValueChanged<AnimalEntity> onAnimalSelected;
  final Future<void> Function() onAddAnimalRequested;
  final VoidCallback onOpenCamera;
  final Future<void> Function() onOpenGallery;
  final ValueChanged<int> onRemoveImage;
  final VoidCallback onAnalyze;

  const ScannerIntakeView({
    super.key,
    required this.animalsFuture,
    required this.selectedAnimal,
    required this.mainReasonController,
    required this.symptomsController,
    required this.temperatureController,
    required this.capturedImages,
    required this.maxImages,
    required this.isSubmitting,
    required this.errorMessage,
    required this.connectivityState,
    required this.geolocationState,
    required this.onAnimalSelected,
    required this.onAddAnimalRequested,
    required this.onOpenCamera,
    required this.onOpenGallery,
    required this.onRemoveImage,
    required this.onAnalyze,
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
          return _EmptyAnimalsCard(
            onAddAnimalRequested: onAddAnimalRequested,
          );
        }

        final isOnline = connectivityState.valueOrNull ?? true;
        final theme = Theme.of(context);
        final appColors = context.appColors;

        return ListView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.xLarge),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSizes.xxLarge),
                boxShadow: [
                  BoxShadow(
                    color: appColors.scannerAccent.withValues(alpha: 0.10),
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
                    style: AppTextStyles.title(theme),
                  ),
                  const SizedBox(height: AppSizes.small + 2),
                  Text(
                    AppStrings.t('diagnosis_real_subtitle'),
                    style: AppTextStyles.bodyMuted(
                      theme,
                      appColors.subduedForeground,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xLarge),
                  if (!isOnline) ...[
                    _OfflineBanner(),
                    const SizedBox(height: AppSizes.large),
                  ],
                  _GeolocationCard(geolocationState: geolocationState),
                  const SizedBox(height: AppSizes.large),

                  // Selector de animal
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
                              '${animal.name} • ${AnimalBreedCatalog.displayLabel(animal.breed)}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      onAnimalSelected(
                        animals.firstWhere((item) => item.id == value),
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.large),

                  // Motivo principal
                  TextField(
                    controller: mainReasonController,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('diagnosis_main_reason'),
                      hintText: AppStrings.t('diagnosis_main_reason_hint'),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSizes.large),

                  // Síntomas
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

                  // Temperatura
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

                  // Thumbnails de imágenes seleccionadas
                  if (capturedImages.isNotEmpty) ...[
                    _ImageThumbnailRow(
                      images: capturedImages,
                      onRemove: onRemoveImage,
                      appColors: appColors,
                    ),
                    const SizedBox(height: AppSizes.large),
                  ],

                  // Botones de foto
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: capturedImages.length >= maxImages
                              ? null
                              : onOpenCamera,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: appColors.scannerAccent,
                            side: BorderSide(
                              color: capturedImages.length >= maxImages
                                  ? appColors.mutedForeground
                                  : appColors.scannerAccent,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.sectionSpacing,
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt),
                          label: Text(AppStrings.t('diagnosis_add_photo')),
                        ),
                      ),
                      const SizedBox(width: AppSizes.medium),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: capturedImages.length >= maxImages
                              ? null
                              : onOpenGallery,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: appColors.scannerAccent,
                            side: BorderSide(
                              color: capturedImages.length >= maxImages
                                  ? appColors.mutedForeground
                                  : appColors.scannerAccent,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.sectionSpacing,
                            ),
                          ),
                          icon: const Icon(Icons.photo_library),
                          label: Text(AppStrings.t('diagnosis_import_photo')),
                        ),
                      ),
                    ],
                  ),

                  // Hint de imágenes
                  if (capturedImages.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.small),
                    Text(
                      '${capturedImages.length}/$maxImages imágenes — toca la X para eliminar',
                      style: AppTextStyles.bodyMuted(
                        theme,
                        appColors.subduedForeground,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSizes.medium),

                  // Botón Analizar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting || !isOnline ? null : onAnalyze,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColors.scannerAccent,
                        foregroundColor: appColors.onSolid,
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  appColors.onSolid,
                                ),
                              ),
                            )
                          : const Icon(Icons.psychology_alt_outlined),
                      label: Text(AppStrings.t('diagnosis_analyze')),
                    ),
                  ),

                  const SizedBox(height: AppSizes.medium),
                  Text(
                    AppStrings.t('diagnosis_camera_optional'),
                    style: AppTextStyles.bodyMuted(
                      theme,
                      appColors.subduedForeground,
                    ),
                  ),

                  // Mensaje de error
                  if (errorMessage != null) ...[
                    const SizedBox(height: AppSizes.large),
                    Text(
                      errorMessage!,
                      style: AppTextStyles.bodyMuted(
                        theme,
                        appColors.danger,
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

// Fila scrolleable de thumbnails con botón X para eliminar
class _ImageThumbnailRow extends StatelessWidget {
  final List<Uint8List> images;
  final ValueChanged<int> onRemove;
  final AppThemeColors appColors;

  const _ImageThumbnailRow({
    required this.images,
    required this.onRemove,
    required this.appColors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.small),
        itemBuilder: (context, index) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
                child: Image.memory(
                  images[index],
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: () => onRemove(index),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: appColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyAnimalsCard extends StatelessWidget {
  final Future<void> Function() onAddAnimalRequested;

  const _EmptyAnimalsCard({required this.onAddAnimalRequested});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxLarge),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.xxLarge),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: appColors.scannerAccent.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pets_outlined,
                  size: AppIconSizes.xxxLarge,
                  color: appColors.mutedForeground,
                ),
                const SizedBox(height: AppSizes.large),
                Text(
                  AppStrings.t('diagnosis'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title(theme),
                ),
                const SizedBox(height: AppSizes.medium),
                Text(
                  AppStrings.t('diagnosis_register_animal_first'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted(
                    theme,
                    appColors.subduedForeground,
                  ),
                ),
                const SizedBox(height: AppSizes.xLarge),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAddAnimalRequested,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(
                        double.infinity,
                        AppSizes.largeButtonHeight,
                      ),
                      backgroundColor: appColors.scannerAccent,
                      foregroundColor: appColors.onSolid,
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(AppStrings.t('register_animal')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppSizes.large),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            appColors.danger.withValues(alpha: 0.14),
            appColors.warning.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.xxLarge),
        border: Border.all(color: appColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.small),
            decoration: BoxDecoration(
              color: appColors.danger,
              borderRadius: BorderRadius.circular(AppSizes.large),
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              color: appColors.onSolid,
              size: AppIconSizes.large,
            ),
          ),
          const SizedBox(width: AppSizes.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t('diagnosis_wifi_required_title'),
                  style: AppTextStyles.bodyStrong(
                    Theme.of(context),
                    Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSizes.xSmall),
                Text(
                  AppStrings.t('diagnosis_wifi_required_message'),
                  style: AppTextStyles.bodyMuted(
                    Theme.of(context),
                    appColors.subduedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GeolocationCard extends ConsumerWidget {
  final AsyncValue<dynamic> geolocationState;

  const _GeolocationCard({required this.geolocationState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appColors = context.appColors;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? appColors.scannerAccent.withValues(alpha: 0.15)
        : appColors.selectionBackground;

    return Container(
      padding: const EdgeInsets.all(AppSizes.sectionSpacing),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, color: appColors.scannerAccent),
          const SizedBox(width: AppSizes.medium),
          Expanded(
            child: geolocationState.when(
              data: (contextValue) {
                if (contextValue == null) {
                  return Text(
                    AppStrings.t('geolocation_unavailable'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t('geolocation_region_ready'),
                      style: AppTextStyles.bodyStrong(
                        theme,
                        theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xSmall),
                    Text(
                      '${AppStrings.t('geolocation_region_label')}: ${contextValue.regionLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppStrings.t('geolocation_climate_label')}: ${contextValue.climateZone}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
              loading: () => Text(
                AppStrings.t('geolocation_loading'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              error: (_, _) => Text(
                AppStrings.t('geolocation_unavailable'),
                style: AppTextStyles.bodyMuted(theme, appColors.danger),
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref
                .read(currentGeolocationContextProvider.notifier)
                .loadCurrentContext(),
            tooltip: AppStrings.t('geolocation_refresh'),
            icon: Icon(
              Icons.refresh,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
