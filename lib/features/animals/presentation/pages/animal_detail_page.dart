import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../medical/presentation/pages/medical_history_page.dart';
import '../../domain/constants/animal_constants.dart';
import '../../domain/entities/animal_entity.dart';
import '../../shared/age_label_formatter.dart';
import '../providers/animal_provider.dart';

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
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _weightController;
  String? _selectedBreedName;
  AnimalAgeOption? _selectedAgeOption;

  File? _newImage;

  final _picker = ImagePicker();

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
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _newImage = File(picked.path));
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
              _handle(),
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
              _handle(),
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
              _handle(),
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

  Future<void> _saveEdit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack(AppStrings.t('required_field'));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final weightText = _weightController.text.trim().replaceAll(',', '.');
      final weight = weightText.isNotEmpty ? double.tryParse(weightText) : null;

      final updatedAnimal = AnimalEntity(
        id: _currentAnimal.id,
        userId: _currentAnimal.userId,
        name: name,
        breed: _selectedBreedName ?? _currentAnimal.breed,
        age: _selectedAgeOption?.months ?? _currentAnimal.age,
        ageLabel: _selectedAgeOption?.label ?? _currentAnimal.ageLabel,
        symptoms: _currentAnimal.symptoms,
        weight: weight,
        temperature: _currentAnimal.temperature,
        imageUrl: _currentAnimal.imageUrl,
        profileImageUrl: _currentAnimal.profileImageUrl,
        createdAt: _currentAnimal.createdAt,
        updatedAt: DateTime.now(),
      );

      await ref.read(animalRepositoryProvider).updateAnimal(
            updatedAnimal,
            localImagePath: _newImage?.path,
          );

      if (!mounted) return;

      setState(() {
        _currentAnimal = updatedAnimal;
        _isEditing = false;
        _isSaving = false;
      });
      ref.invalidate(animalsListProvider);
      _snack(AppStrings.t('saved_ok'));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _snack('${AppStrings.t('save_error')}: $e');
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(animalRepositoryProvider).deleteAnimal(_currentAnimal.id);
      ref.invalidate(animalsListProvider);
      if (mounted) {
        _snack(AppStrings.t('animal_deleted'));
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        _snack(AppStrings.t('delete_error'));
      }
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _handle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: context.appColors.inputBorderLight,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              onPressed: () => setState(() {
                _isEditing = false;
                _resetEditState();
              }),
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
            _buildProfileImage(isDark),
            const SizedBox(height: 20),
            if (_isEditing) _buildEditForm() else _buildViewMode(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(bool isDark) {
    Widget imageContent;
    if (_newImage != null) {
      imageContent = Image.file(
        _newImage!,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
      );
    } else if (_currentAnimal.profileImageUrl != null &&
        _currentAnimal.profileImageUrl!.isNotEmpty) {
      imageContent = Image.network(
        _currentAnimal.profileImageUrl!,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _defaultImageAsset(),
      );
    } else {
      imageContent = _defaultImageAsset();
    }

    final overlayColor = _isEditing
        ? Colors.black.withValues(alpha: 0.40)
        : Colors.black.withValues(alpha: 0.28);
    final overlayIcon =
        _isEditing ? Icons.camera_alt : Icons.add_a_photo_outlined;
    final overlayText =
        _isEditing ? AppStrings.t('change_photo') : AppStrings.t('add_photo');

    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageContent,
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: overlayColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(overlayIcon, size: 36, color: Colors.white),
                  const SizedBox(height: 6),
                  Text(
                    overlayText,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultImageAsset() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        AppStrings.t('animal_default_image'),
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
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
        _infoRow(Icons.pets, AppStrings.t('breed_label'), _currentAnimal.breed),
        _infoRow(
          Icons.cake,
          AppStrings.t('age_label'),
          _currentAnimal.ageLabel.isNotEmpty
              ? _currentAnimal.ageLabel
              : AgeLabelFormatter.format(_currentAnimal.age),
        ),
        _infoRow(
          Icons.monitor_weight_outlined,
          AppStrings.t('weight_label'),
          weightText,
        ),
        if (_currentAnimal.temperature != null)
          _infoRow(
            Icons.thermostat,
            AppStrings.t('temperature_label'),
            '${_currentAnimal.temperature} °C',
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.medical_services),
            label: Text(AppStrings.t('view_medical_history')),
            onPressed: () async {
              final updated = await Navigator.push<AnimalEntity>(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicalHistoryPage(animal: _currentAnimal),
                ),
              );

              if (updated != null && mounted) {
                setState(() => _currentAnimal = updated);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
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
              overflow: TextOverflow.visible,
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
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9 ]'),
            ),
          ],
          decoration: InputDecoration(
            labelText: '${AppStrings.t('name')} *',
            prefixIcon: Icon(Icons.pets, color: appColors.chipForeground),
          ),
        ),
        const SizedBox(height: 14),
        _selectorField(
          label: AppStrings.t('breed_label'),
          selectedValue: _selectedBreedName,
          icon: Icons.category_outlined,
          onTap: _showBreedSelector,
        ),
        const SizedBox(height: 14),
        _selectorField(
          label: AppStrings.t('age_label'),
          selectedValue: _selectedAgeOption?.label,
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
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _selectorField({
    required String label,
    required String? selectedValue,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final appColors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: appColors.inputBorderLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: appColors.chipForeground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedValue ?? label,
                style: TextStyle(
                  fontSize: 16,
                  color: selectedValue != null
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : appColors.mutedForeground,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: appColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
