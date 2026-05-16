import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../medical/presentation/pages/medical_history_page.dart';
import '../../domain/constants/animal_breed_catalog.dart';
import '../../domain/constants/animal_constants.dart';
import '../../domain/entities/animal_entity.dart';
import '../../shared/age_label_formatter.dart';
import '../controllers/animal_form_controller.dart';
import '../providers/animal_provider.dart';
import '../providers/animal_reference_catalog_provider.dart';
import '../widgets/animal_detail_edit_form.dart';
import '../widgets/animal_detail_view_mode.dart';
import '../widgets/animal_image_card.dart';
import '../widgets/animal_image_source_sheet.dart';
import '../widgets/animal_option_picker_sheet.dart';

class AnimalDetailPage extends ConsumerStatefulWidget {
  final AnimalEntity animal;

  const AnimalDetailPage({super.key, required this.animal});

  @override
  ConsumerState<AnimalDetailPage> createState() => _AnimalDetailPageState();
}

class _AnimalDetailPageState extends ConsumerState<AnimalDetailPage> {
  late AnimalEntity _currentAnimal;
  late AnimalFormController _formController;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUpdatingPhoto = false;

  @override
  void initState() {
    super.initState();
    _currentAnimal = widget.animal;
    _initFormController();
  }

  void _initFormController() {
    _formController = AnimalFormController(
      initialName: _currentAnimal.name,
      initialWeight:
          _currentAnimal.weight != null ? '${_currentAnimal.weight}' : '',
      selectedBreedKey: AnimalBreedCatalog.storageValue(_currentAnimal.breed),
      selectedAgeOption: _resolveCurrentAgeOption(),
    );
  }

  AnimalAgeOption _resolveCurrentAgeOption() {
    final ageOptions = ref.read(animalAgeOptionsProvider).valueOrNull ?? const [];
    return ageOptions.firstWhere(
      (o) => o.months == _currentAnimal.age,
      orElse: () => AnimalAgeOption(
        label: _currentAnimal.ageLabel.isNotEmpty
            ? _currentAnimal.ageLabel
            : AgeLabelFormatter.format(_currentAnimal.age),
        months: _currentAnimal.age,
      ),
    );
  }

  void _resetEditState() {
    _formController.dispose();
    _initFormController();
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  void _goHome() => Navigator.of(context).popUntil((r) => r.isFirst);

  // ---------------------------------------------------------------------------
  // Imagen
  // ---------------------------------------------------------------------------

  Future<void> _pickImage(ImageSource source) async {
    final image = await _formController.pickImage(source);
    if (image == null) return;

    if (_isEditing) {
      setState(() {});
      return;
    }
    await _savePhotoUpdate(image);
  }

  void _showImageSourceDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Theme.of(context).colorScheme.surface.withValues(alpha: 0),
      builder: (_) => AnimalImageSourceSheet(
        onSourceSelected: (source) {
          Navigator.pop(context);
          _pickImage(source);
        },
      ),
    );
  }

  Future<void> _savePhotoUpdate(File imageFile) async {
    if (_isUpdatingPhoto) return;

    setState(() => _isUpdatingPhoto = true);

    try {
      final updatedAnimal = _currentAnimal.copyWith(updatedAt: DateTime.now());
      await ref.read(animalRepositoryProvider).updateAnimal(
            updatedAnimal,
            localImagePath: imageFile.path,
          );

      if (!mounted) return;

      setState(() {
        _currentAnimal = updatedAnimal.copyWith(
          localProfileImagePath: imageFile.path,
        );
        _formController.selectedImage = null;
        _isUpdatingPhoto = false;
      });
      refreshAnimals(ref);
      _showSnack(AppStrings.t('medical_photo_updated'));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _formController.selectedImage = null;
        _isUpdatingPhoto = false;
      });
      _showSnack('${AppStrings.t('save_error')}: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Selección de raza y edad
  // ---------------------------------------------------------------------------

  Future<void> _showBreedSelector() async {
    final breedChoices = await ref.read(animalBreedChoicesProvider.future);
    if (!mounted) return;

    if (breedChoices.isEmpty) {
      _showSnack(AppStrings.t('internet_required_default'));
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Theme.of(context).colorScheme.surface.withValues(alpha: 0),
      builder: (_) => AnimalOptionPickerSheet(
        title: AppStrings.t('select_breed'),
        options: breedChoices
            .map((b) => AnimalOptionItem(value: b.value, label: b.label))
            .toList(),
        selectedValue: _formController.selectedBreedKey,
        onOptionSelected: (key) {
          setState(() => _formController.selectedBreedKey = key);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _showAgeSelector() async {
    final ageOptions = await ref.read(animalAgeOptionsProvider.future);
    if (!mounted) return;

    if (ageOptions.isEmpty) {
      _showSnack(AppStrings.t('internet_required_default'));
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Theme.of(context).colorScheme.surface.withValues(alpha: 0),
      builder: (_) => AnimalOptionPickerSheet(
        title: AppStrings.t('select_age'),
        options: ageOptions
            .map((o) => AnimalOptionItem(value: o.months.toString(), label: o.label))
            .toList(),
        selectedValue: _formController.selectedAgeOption?.months.toString(),
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        onOptionSelected: (value) {
          final selected =
              ageOptions.firstWhere((o) => o.months.toString() == value);
          setState(() => _formController.selectedAgeOption = selected);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Guardar edición
  // ---------------------------------------------------------------------------

  Future<void> _saveEdit() async {
    final name = _formController.nameController.text.trim();
    if (name.isEmpty) {
      _showSnack(AppStrings.t('required_field'));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final weight = _formController.parseWeight();
      final updatedAnimal = _currentAnimal.copyWith(
        name: name,
        breed: _formController.selectedBreedKey,
        age: _formController.selectedAgeOption?.months,
        ageLabel: _formController.selectedAgeOption?.label,
        weight: weight,
        clearWeight: weight == null,
        updatedAt: DateTime.now(),
      );

      await ref.read(animalRepositoryProvider).updateAnimal(
            updatedAnimal,
            localImagePath: _formController.selectedImage?.path,
          );

      if (!mounted) return;

      setState(() {
        _currentAnimal = updatedAnimal.copyWith(
          localProfileImagePath: _formController.selectedImage?.path ??
              _currentAnimal.localProfileImagePath,
        );
        _formController.selectedImage = null;
        _isEditing = false;
        _isSaving = false;
      });
      refreshAnimals(ref);
      _showSnack(AppStrings.t('saved_ok'));
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('${AppStrings.t('save_error')}: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Eliminar
  // ---------------------------------------------------------------------------

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _buildDeleteDialog(dialogContext),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(animalRepositoryProvider).deleteAnimal(_currentAnimal.id);
      refreshAnimals(ref);
      if (!mounted) return;
      _showSnack(AppStrings.t('animal_deleted'));
      Navigator.pop(context);
    } catch (_) {
      if (mounted) _showSnack(AppStrings.t('delete_error'));
    }
  }

  Widget _buildDeleteDialog(BuildContext dialogContext) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.large),
      ),
      title: Text(AppStrings.t('delete_animal')),
      content: Text(AppStrings.t('delete_animal_confirm')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(AppStrings.t('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            AppStrings.t('delete'),
            style: TextStyle(color: context.appColors.chipForeground),
          ),
        ),
      ],
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Actualiza el animal si cambió externamente (sin sobrescribir edición activa).
    final latestAnimal =
        ref.watch(animalByIdProvider(_currentAnimal.id)).valueOrNull;
    if (!_isEditing && latestAnimal != null && latestAnimal != _currentAnimal) {
      _currentAnimal = latestAnimal;
    }

    final hasPhoto = _formController.selectedImage != null ||
        (_currentAnimal.localProfileImagePath?.isNotEmpty ?? false) ||
        (_currentAnimal.profileImageUrl?.isNotEmpty ?? false);

    return Scaffold(
      appBar: _buildAppBar(),
      floatingActionButton: _isEditing ? _buildSaveFab() : null,
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
            _buildImageSection(hasPhoto),
            const SizedBox(height: AppSizes.xLarge),
            if (_isEditing)
              AnimalDetailEditForm(
                formController: _formController,
                onBreedTap: _showBreedSelector,
                onAgeTap: _showAgeSelector,
              )
            else
              AnimalDetailViewMode(
                animal: _currentAnimal,
                onMedicalHistoryTap: () async {
                  final updatedAnimal = await Navigator.push<AnimalEntity>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MedicalHistoryPage(animal: _currentAnimal),
                    ),
                  );
                  if (updatedAnimal != null && mounted) {
                    setState(() => _currentAnimal = updatedAnimal);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
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
            icon: const Icon(Icons.delete_outline),
            tooltip: AppStrings.t('delete_animal'),
            onPressed: _confirmDelete,
          ),
        ] else
          TextButton(
            onPressed: () {
              setState(() {
                _isEditing = false;
                _resetEditState();
              });
            },
            child: Text(
              AppStrings.t('cancel'),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildSaveFab() {
    final isBusy = _isSaving || _isUpdatingPhoto;
    return FloatingActionButton.extended(
      onPressed: isBusy ? null : _saveEdit,
      icon: isBusy
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
    );
  }

  Widget _buildImageSection(bool hasPhoto) {
    final imageActionLabel = hasPhoto
        ? AppStrings.t('change_photo')
        : AppStrings.t('add_photo');
    final imageActionIcon =
        hasPhoto ? Icons.add_a_photo_outlined : Icons.camera_alt_outlined;

    return Column(
      children: [
        AnimalImageCard(
          selectedImage: _formController.selectedImage,
          localImagePath: _currentAnimal.localProfileImagePath,
          networkImageUrl: _currentAnimal.profileImageUrl,
          height: AppSizes.animalDetailImageHeight,
          borderRadius: BorderRadius.circular(AppSizes.large),
          onTap: hasPhoto && !_isEditing ? () {} : _showImageSourceDialog,
          overlayLabel: _isEditing
              ? AppStrings.t('change_photo')
              : AppStrings.t('add_photo'),
          overlayIcon:
              _isEditing ? Icons.camera_alt : Icons.add_a_photo_outlined,
          showOverlay: _isEditing || !hasPhoto,
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
      ],
    );
  }
}
