import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/livestock_icon.dart';
import '../../../medical/presentation/pages/medical_history_page.dart';
import '../../data/services/animal_reference_catalog_service.dart';
import '../../domain/constants/animal_constants.dart';
import '../../domain/constants/animal_breed_catalog.dart';
import '../../domain/entities/animal_entity.dart';
import '../../shared/age_label_formatter.dart';
import '../../shared/animal_input_formatters.dart';
import '../providers/animal_reference_catalog_provider.dart';
import '../providers/animal_provider.dart';
import '../widgets/animal_image_card.dart';
import '../widgets/animal_image_source_sheet.dart';
import '../widgets/animal_option_picker_sheet.dart';
import '../widgets/animal_selector_field.dart';

class AnimalDetailPage extends ConsumerStatefulWidget {
  final AnimalEntity animal;

  const AnimalDetailPage({
    super.key,
    required this.animal,
  });

  @override
  ConsumerState<AnimalDetailPage> createState() => _AnimalDetailPageState();
}

class _AnimalDetailPageState extends ConsumerState<AnimalDetailPage> {
  late AnimalEntity _currentAnimal;
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _weightController;
  String? _selectedBreedKey;
  AnimalAgeOption? _selectedAgeOption;

  File? _newImage;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUpdatingPhoto = false;

  @override
  void initState() {
    super.initState();
    _currentAnimal = widget.animal;
    _resetEditState();
  }

  void _resetEditState() {
    _nameController = TextEditingController(text: _currentAnimal.name);
    _weightController = TextEditingController(
      text: _currentAnimal.weight != null ? '${_currentAnimal.weight}' : '',
    );
    _selectedBreedKey = AnimalBreedCatalog.storageValue(_currentAnimal.breed);

    final ageOptions = ref.read(animalAgeOptionsProvider).valueOrNull ?? const [];
    _selectedAgeOption = ageOptions.firstWhere(
      (ageOption) => ageOption.months == _currentAnimal.age,
      orElse: () => AnimalAgeOption(
        label: _currentAnimal.ageLabel.isNotEmpty
            ? _currentAnimal.ageLabel
            : AgeLabelFormatter.format(_currentAnimal.age),
        months: _currentAnimal.age,
      ),
    );

    _newImage = null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedImage = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedImage == null) {
      return;
    }

    final pickedFile = File(pickedImage.path);

    if (_isEditing) {
      setState(() => _newImage = pickedFile);
      return;
    }

    await _savePhotoUpdate(pickedFile);
  }

  Future<void> _savePhotoUpdate(File imageFile) async {
    if (_isUpdatingPhoto) {
      return;
    }

    setState(() {
      _isUpdatingPhoto = true;
      _newImage = imageFile;
    });

    try {
      final updatedAnimal = _currentAnimal.copyWith(updatedAt: DateTime.now());
      await ref.read(animalRepositoryProvider).updateAnimal(
            updatedAnimal,
            localImagePath: imageFile.path,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentAnimal = updatedAnimal.copyWith(
          localProfileImagePath: imageFile.path,
        );
        _newImage = null;
        _isUpdatingPhoto = false;
      });
      refreshAnimals(ref);
      _showSnack(AppStrings.t('medical_photo_updated'));
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _newImage = null;
        _isUpdatingPhoto = false;
      });
      _showSnack('${AppStrings.t('save_error')}: $error');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0),
      builder: (_) {
        return AnimalImageSourceSheet(
          onSourceSelected: (source) {
            Navigator.pop(context);
            _pickImage(source);
          },
        );
      },
    );
  }

  Future<void> _showBreedSelector() async {
    final breedChoices = await ref.read(animalBreedChoicesProvider.future);
    if (!mounted) {
      return;
    }

    if (breedChoices.isEmpty) {

      _showSnack(AppStrings.t('internet_required_default'));
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0),
      builder: (_) {
        return AnimalOptionPickerSheet(
          title: AppStrings.t('select_breed'),
          options: breedChoices
              .map(
                (breedChoice) => AnimalOptionItem(
                  value: breedChoice.value,
                  label: breedChoice.label,
                ),
              )
              .toList(),
          selectedValue: _selectedBreedKey,
          onOptionSelected: (breedKey) {
            setState(() => _selectedBreedKey = breedKey);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _showAgeSelector() async {
    final ageOptions = await ref.read(animalAgeOptionsProvider.future);
    if (!mounted) {
      return;
    }

    if (ageOptions.isEmpty) {

      _showSnack(AppStrings.t('internet_required_default'));
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0),
      builder: (_) {
        return AnimalOptionPickerSheet(
          title: AppStrings.t('select_age'),
          options: ageOptions
              .map(
                (option) => AnimalOptionItem(
                  value: option.months.toString(),
                  label: option.label,
                ),
              )
              .toList(),
          selectedValue: _selectedAgeOption?.months.toString(),
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          onOptionSelected: (selectedValue) {
            final selectedAgeOption = ageOptions.firstWhere(
              (option) => option.months.toString() == selectedValue,
            );
            setState(() => _selectedAgeOption = selectedAgeOption);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _saveEdit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack(AppStrings.t('required_field'));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final normalizedWeight = _weightController.text.trim().replaceAll(',', '.');
      final updatedAnimal = _currentAnimal.copyWith(
        name: name,
        breed: _selectedBreedKey,
        age: _selectedAgeOption?.months,
        ageLabel: _selectedAgeOption?.label,
        weight: normalizedWeight.isEmpty
            ? null
            : double.tryParse(normalizedWeight),
        clearWeight: normalizedWeight.isEmpty,
        updatedAt: DateTime.now(),
      );

      await ref.read(animalRepositoryProvider).updateAnimal(
            updatedAnimal,
            localImagePath: _newImage?.path,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentAnimal = updatedAnimal.copyWith(
          localProfileImagePath:
              _newImage?.path ?? _currentAnimal.localProfileImagePath,
        );
        _newImage = null;
        _isEditing = false;
        _isSaving = false;
      });
      refreshAnimals(ref);
      _showSnack(AppStrings.t('saved_ok'));
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);
      _showSnack('${AppStrings.t('save_error')}: $error');
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppStrings.t('delete_animal'),
            style: AppTextStyles.sectionTitle(Theme.of(context)),
          ),
          content: Text(AppStrings.t('delete_animal_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(AppStrings.t('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColors.danger,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(AppStrings.t('delete')),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await ref.read(animalRepositoryProvider).deleteAnimal(_currentAnimal.id);
      refreshAnimals(ref);

      if (!mounted) {
        return;
      }

      _showSnack(AppStrings.t('animal_deleted'));
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        _showSnack(AppStrings.t('delete_error'));
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animalAsync = ref.watch(animalByIdProvider(_currentAnimal.id));
    final latestAnimal = animalAsync.valueOrNull;
    if (!_isEditing && latestAnimal != null && latestAnimal != _currentAnimal) {
      _currentAnimal = latestAnimal;
    }

    final hasAnimalPhoto =
        _newImage != null ||
        (_currentAnimal.localProfileImagePath?.isNotEmpty ?? false) ||
        (_currentAnimal.profileImageUrl?.isNotEmpty ?? false);
    final imageActionLabel = hasAnimalPhoto
        ? AppStrings.t('change_photo')
        : AppStrings.t('add_photo');
    final imageActionIcon = hasAnimalPhoto
        ? Icons.add_a_photo_outlined
        : Icons.camera_alt_outlined;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? AppStrings.t('edit_animal') : _currentAnimal.name,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: AppStrings.t('go_home'),
            onPressed: _goHome,
          ),
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppStrings.t('edit_animal'),
              onPressed: () => setState(() => _isEditing = true),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: context.appColors.danger),
              tooltip: AppStrings.t('delete_animal'),
              onPressed: _confirmDelete,
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _resetEditState();
                });
              },
              child: Text(
                AppStrings.t('cancel'),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: _isEditing
          ? FloatingActionButton.extended(
              onPressed: (_isSaving || _isUpdatingPhoto) ? null : _saveEdit,
              icon: (_isSaving || _isUpdatingPhoto)
                  ? SizedBox(
                      width: AppIconSizes.medium,
                      height: AppIconSizes.medium,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(AppStrings.t('save_changes')),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.large,
          AppSizes.large,
          AppSizes.large,
          AppSizes.formBottomSpacing + AppSizes.xLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimalImageCard(
              selectedImage: _newImage,
              localImagePath: _currentAnimal.localProfileImagePath,
              networkImageUrl: _currentAnimal.profileImageUrl,
              height: AppSizes.animalDetailImageHeight,
              borderRadius: BorderRadius.circular(AppSizes.large),
              onTap:
                  hasAnimalPhoto && !_isEditing ? () {} : _showImageSourceDialog,
              overlayLabel: _isEditing
                  ? AppStrings.t('change_photo')
                  : AppStrings.t('add_photo'),
              overlayIcon:
                  _isEditing ? Icons.camera_alt : Icons.add_a_photo_outlined,
              showOverlay: _isEditing || !hasAnimalPhoto,
            ),
            const SizedBox(height: AppSizes.medium),
            Align(
              alignment: Alignment.center,
              child: OutlinedButton.icon(
                onPressed: _isUpdatingPhoto ? null : _showImageSourceDialog,
                icon: _isUpdatingPhoto
                    ? SizedBox(
                        width: AppIconSizes.medium,
                        height: AppIconSizes.medium,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : Icon(imageActionIcon),
                label: Text(imageActionLabel),
              ),
            ),
            const SizedBox(height: AppSizes.xLarge),
            if (_isEditing) _buildEditForm() else _buildViewMode(),
          ],
        ),
      ),
    );
  }

  Widget _buildViewMode() {
    final breedChoices =
        ref.watch(animalBreedChoicesProvider).valueOrNull ?? const [];
    final weightText = _currentAnimal.weight != null
        ? '${_currentAnimal.weight} ${AppStrings.t('kg')}'
        : AppStrings.t('weight_no_data');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          null,
          AppStrings.t('breed_label'),
          AnimalReferenceCatalogService.resolveBreedLabel(
            _currentAnimal.breed,
            choices: breedChoices,
          ),
        ),
        _buildInfoRow(
          Icons.cake,
          AppStrings.t('age_label'),
          _currentAnimal.ageLabel.isNotEmpty
              ? _currentAnimal.ageLabel
              : AgeLabelFormatter.format(_currentAnimal.age),
        ),
        _buildInfoRow(
          Icons.monitor_weight_outlined,
          AppStrings.t('weight_label'),
          weightText,
        ),
        if (_currentAnimal.temperature != null)
          _buildInfoRow(
            Icons.thermostat,
            AppStrings.t('temperature_label'),
            '${_currentAnimal.temperature} \u00B0C',
          ),
        const SizedBox(height: AppSizes.xxLarge),
        SizedBox(
          width: double.infinity,
          height: AppSizes.largeButtonHeight,
          child: ElevatedButton.icon(
            onPressed: () async {
              final updatedAnimal = await Navigator.push<AnimalEntity>(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicalHistoryPage(animal: _currentAnimal),
                ),
              );

              if (updatedAnimal != null && mounted) {
                setState(() => _currentAnimal = updatedAnimal);
              }
            },
            icon: const Icon(Icons.medical_services),
            label: Text(AppStrings.t('view_medical_history')),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData? icon, String label, String value) {
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

  Widget _buildEditForm() {
    final appColors = context.appColors;
    final breedChoices =
        ref.watch(animalBreedChoicesProvider).valueOrNull ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          inputFormatters: [AnimalInputFormatters.name],
          decoration: InputDecoration(
            labelText: '${AppStrings.t('name')} *',
            prefixIcon: const LivestockIcon(
              padding: EdgeInsets.all(12),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sectionSpacing),
        AnimalSelectorField(
          label: AppStrings.t('breed_label'),
          value: _selectedBreedKey == null
              ? null
              : AnimalReferenceCatalogService.resolveBreedLabel(
                  _selectedBreedKey,
                  choices: breedChoices,
                ),
          icon: Icons.category_outlined,
          onTap: _showBreedSelector,
        ),
        const SizedBox(height: AppSizes.sectionSpacing),
        AnimalSelectorField(
          label: AppStrings.t('age_label'),
          value: _selectedAgeOption?.label,
          icon: Icons.cake_outlined,
          onTap: _showAgeSelector,
        ),
        const SizedBox(height: AppSizes.sectionSpacing),
        TextFormField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [AnimalInputFormatters.decimal],
          decoration: InputDecoration(
            labelText: '${AppStrings.t('weight')} - ${AppStrings.t('optional')}',
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
