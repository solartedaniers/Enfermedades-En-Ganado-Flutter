import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/constants/animal_constants.dart';
import '../../domain/entities/animal_entity.dart';
import '../../shared/age_label_formatter.dart';
import '../../shared/animal_input_formatters.dart';
import '../../../profile/presentation/providers/managed_client_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/animal_provider.dart';
import '../widgets/animal_image_card.dart';
import '../widgets/animal_image_source_sheet.dart';
import '../widgets/animal_option_picker_sheet.dart';
import '../widgets/animal_selector_field.dart';

class AddAnimalPage extends ConsumerStatefulWidget {
  const AddAnimalPage({super.key});

  @override
  ConsumerState<AddAnimalPage> createState() => _AddAnimalPageState();
}

class _AddAnimalPageState extends ConsumerState<AddAnimalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _picker = ImagePicker();

  File? _selectedImage;
  String? _selectedBreedName;
  AnimalAgeOption? _selectedAgeOption;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedImage = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedImage == null) {
      return;
    }

    setState(() => _selectedImage = File(pickedImage.path));
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBreedName == null || _selectedAgeOption == null) {
      _showSnack(AppStrings.t('required_field'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId == null) {
        throw Exception(AppStrings.t('error_no_session'));
      }

      final normalizedWeight = _weightController.text.trim().replaceAll(',', '.');
      final weight =
          normalizedWeight.isEmpty ? null : double.tryParse(normalizedWeight);
      final now = DateTime.now();

      final animal = AnimalEntity(
        id: const Uuid().v4(),
        userId: currentUserId,
        name: _nameController.text.trim(),
        breed: _selectedBreedName!,
        age: _selectedAgeOption!.months,
        ageLabel: _selectedAgeOption!.label,
        symptoms: '',
        weight: weight,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(animalRepositoryProvider).addAnimal(
            animal,
            localImagePath: _selectedImage?.path,
          );
      final profile = ref.read(profileProvider);
      if (profile.isVeterinarian) {
        await ref
            .read(managedClientProvider.notifier)
            .assignAnimalToActiveClient(animal.id);
      }

      if (!mounted) {
        return;
      }

      _showSnack(AppStrings.t('saved_ok'));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnack('${AppStrings.t('save_error')}: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
    final appColors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('add_animal'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimalImageCard(
                selectedImage: _selectedImage,
                networkImageUrl: null,
                height: 180,
                borderRadius: BorderRadius.circular(20),
                onTap: _showImageSourceDialog,
                overlayLabel: AppStrings.t('add_photo'),
                overlaySubtitle: AppStrings.t('photo_subtitle'),
                overlayIcon: Icons.add_a_photo,
              ).animate().fadeIn(duration: 400.ms).scale(
                    begin: const Offset(0.95, 0.95),
                  ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                inputFormatters: [AnimalInputFormatters.name],
                decoration: InputDecoration(
                  labelText: '${AppStrings.t('name')} *',
                  prefixIcon: Icon(Icons.pets, color: appColors.chipForeground),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.t('required_field');
                  }
                  return null;
                },
              ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.03),
              const SizedBox(height: 14),
              AnimalSelectorField(
                label: '${AppStrings.t('breed')} *',
                value: _selectedBreedName,
                icon: Icons.category_outlined,
                onTap: _showBreedSelector,
              ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.03),
              const SizedBox(height: 14),
              AnimalSelectorField(
                label: '${AppStrings.t('age')} *',
                value: _selectedAgeOption?.label,
                icon: Icons.cake_outlined,
                onTap: _showAgeSelector,
              ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.03),
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
              ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.03),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(AppStrings.t('save')),
                ),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
