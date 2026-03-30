import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/constants/animal_constants.dart';
import '../../domain/entities/animal_entity.dart';
import '../../shared/age_label_formatter.dart';
import '../providers/animal_provider.dart';

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
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _showImageSourceDialog() {
    final appColors = context.appColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              ListTile(
                leading: Icon(Icons.camera_alt, color: appColors.chipForeground),
                title: Text(AppStrings.t('take_photo')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.photo_library, color: appColors.chipForeground),
                title: Text(AppStrings.t('choose_gallery')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showBreedSelector() {
    final appColors = context.appColors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _sheetHandle(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  AppStrings.t('select_breed'),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: AnimalConstants.cattleBreeds.length,
                  itemBuilder: (_, index) {
                    final breed = AnimalConstants.cattleBreeds[index];
                    final isSelected = breed == _selectedBreedName;
                    return ListTile(
                      title: Text(breed),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: appColors.chipForeground)
                          : null,
                      tileColor: isSelected ? appColors.selectionBackground : null,
                      onTap: () {
                        setState(() => _selectedBreedName = breed);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAgeSelector() {
    final ageOptions = AgeLabelFormatter.buildAgeOptions();
    final appColors = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _sheetHandle(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  AppStrings.t('select_age'),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: ageOptions.length,
                  itemBuilder: (_, index) {
                    final ageOption = ageOptions[index];
                    final isSelected =
                        ageOption.months == _selectedAgeOption?.months;
                    return ListTile(
                      title: Text(ageOption.label),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: appColors.chipForeground)
                          : null,
                      tileColor: isSelected ? appColors.selectionBackground : null,
                      onTap: () {
                        setState(() => _selectedAgeOption = ageOption);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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

      final localPath = _selectedImage?.path;

      double? weight;
      final weightText = _weightController.text.trim().replaceAll(',', '.');
      if (weightText.isNotEmpty) {
        weight = double.tryParse(weightText);
      }

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
        temperature: null,
        imageUrl: null,
        profileImageUrl: null,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(animalRepositoryProvider).addAnimal(
            animal,
            localImagePath: localPath,
          );

      if (mounted) {
        _showSnack(AppStrings.t('saved_ok'));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('${AppStrings.t('save_error')}: $e');
      }
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

  Widget _sheetHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
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
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                AppStrings.t('animal_default_image'),
                                fit: BoxFit.cover,
                              ),
                              Container(color: Colors.black.withValues(alpha: 0.45)),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo, size: 44, color: Colors.white),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppStrings.t('add_photo'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppStrings.t('photo_subtitle'),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9 ]'),
                  ),
                ],
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
              _buildSelector(
                label: '${AppStrings.t('breed')} *',
                value: _selectedBreedName,
                icon: Icons.category_outlined,
                onTap: _showBreedSelector,
              ),
              const SizedBox(height: 14),
              _buildSelector(
                label: '${AppStrings.t('age')} *',
                value: _selectedAgeOption?.label,
                icon: Icons.cake_outlined,
                onTap: _showAgeSelector,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                decoration: InputDecoration(
                  labelText: '${AppStrings.t('weight')} — ${AppStrings.t('optional')}',
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

  Widget _buildSelector({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final appColors = context.appColors;
    final hasValue = value != null && value.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: appColors.chipForeground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasValue ? value : label,
                style: TextStyle(
                  fontSize: 16,
                  color: hasValue ? null : Colors.grey.shade600,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.03);
  }
}
