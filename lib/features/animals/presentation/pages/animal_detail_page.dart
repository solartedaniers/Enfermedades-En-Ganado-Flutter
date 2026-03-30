import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../medical/presentation/pages/medical_history_page.dart';
import '../../domain/constants/animal_constants.dart';
import '../../domain/entities/animal_entity.dart';
import '../../shared/age_label_formatter.dart';
import '../../shared/animal_input_formatters.dart';
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
  String? _selectedBreedName;
  AnimalAgeOption? _selectedAgeOption;

  File? _newImage;
  bool _isEditing = false;
  bool _isSaving = false;

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
    _selectedBreedName = _currentAnimal.breed;

    final ageOptions = AgeLabelFormatter.buildAgeOptions();
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

    setState(() => _newImage = File(pickedImage.path));
  }

  void _showImageSourceDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
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

  void _showBreedSelector() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AnimalOptionPickerSheet(
          title: AppStrings.t('select_breed'),
          options: AnimalConstants.cattleBreeds,
          selectedValue: _selectedBreedName,
          onOptionSelected: (breed) {
            setState(() => _selectedBreedName = breed);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _showAgeSelector() {
    final ageOptions = AgeLabelFormatter.buildAgeOptions();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AnimalOptionPickerSheet(
          title: AppStrings.t('select_age'),
          options: ageOptions.map((option) => option.label).toList(),
          selectedValue: _selectedAgeOption?.label,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          onOptionSelected: (label) {
            final selectedAgeOption = ageOptions.firstWhere(
              (option) => option.label == label,
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
        breed: _selectedBreedName,
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
        _currentAnimal = updatedAnimal;
        _isEditing = false;
        _isSaving = false;
      });
      ref.invalidate(animalsListProvider);
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
            style: const TextStyle(fontWeight: FontWeight.bold),
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
      ref.invalidate(animalsListProvider);

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
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: _isEditing
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveEdit,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(AppStrings.t('save_changes')),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimalImageCard(
              selectedImage: _newImage,
              networkImageUrl: _currentAnimal.profileImageUrl,
              height: 220,
              borderRadius: BorderRadius.circular(16),
              onTap: _showImageSourceDialog,
              overlayLabel: _isEditing
                  ? AppStrings.t('change_photo')
                  : AppStrings.t('add_photo'),
              overlayIcon:
                  _isEditing ? Icons.camera_alt : Icons.add_a_photo_outlined,
            ),
            const SizedBox(height: 20),
            if (_isEditing) _buildEditForm() else _buildViewMode(),
          ],
        ),
      ),
    );
  }

  Widget _buildViewMode() {
    final weightText = _currentAnimal.weight != null
        ? '${_currentAnimal.weight} ${AppStrings.t('kg')}'
        : AppStrings.t('weight_no_data');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          Icons.pets,
          AppStrings.t('breed_label'),
          _currentAnimal.breed,
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
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final appColors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: appColors.chipForeground, size: 20),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    final appColors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          inputFormatters: [AnimalInputFormatters.name],
          decoration: InputDecoration(
            labelText: '${AppStrings.t('name')} *',
            prefixIcon: Icon(Icons.pets, color: appColors.chipForeground),
          ),
        ),
        const SizedBox(height: 14),
        AnimalSelectorField(
          label: AppStrings.t('breed_label'),
          value: _selectedBreedName,
          icon: Icons.category_outlined,
          onTap: _showBreedSelector,
        ),
        const SizedBox(height: 14),
        AnimalSelectorField(
          label: AppStrings.t('age_label'),
          value: _selectedAgeOption?.label,
          icon: Icons.cake_outlined,
          onTap: _showAgeSelector,
        ),
        const SizedBox(height: 14),
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
        const SizedBox(height: 80),
      ],
    );
  }
}
