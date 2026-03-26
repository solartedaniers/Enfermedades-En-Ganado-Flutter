import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/animal_entity.dart';
import '../providers/animal_provider.dart';
import '../../../medical/presentation/pages/medical_history_page.dart';

// ── Razas (misma lista que add_animal_page) ────────────────────────────────
const List<String> _cattleBreeds = [
  'Aberdeen Angus', 'Beefmaster', 'Belgian Blue', "Blonde d'Aquitaine",
  'Bonsmara', 'Brahman', 'Brangus', 'Brown Swiss', 'Charolais', 'Chianina',
  'Criollo', 'Devon', 'Droughtmaster', 'Fleckvieh', 'Gelbvieh', 'Gir',
  'Guzerá', 'Hereford', 'Holstein Friesian', 'Jersey', 'Limousin', 'Longhorn',
  'Maine-Anjou', 'Marchigiana', 'Montbéliarde', 'Murray Grey', 'Nelore',
  'Normande', 'Piedmontese', 'Pinzgauer', 'Red Angus', 'Red Poll',
  'Romosinuano', 'Sahiwal', 'Salorn', 'Santa Gertrudis', 'Senepol',
  'Shorthorn', 'Simmental', 'Taurus', 'Zebu (Cebú)',
];

// ── Opciones de edad ───────────────────────────────────────────────────────
class _AgeOption {
  final String label;
  final int months;
  const _AgeOption({required this.label, required this.months});
}

List<_AgeOption> _buildAgeOptions() {
  return [
    for (int m = 1; m <= 11; m++)
      _AgeOption(label: AnimalEntity.defaultAgeLabel(m), months: m),
    for (int y = 1; y <= 25; y++)
      _AgeOption(
          label: AnimalEntity.defaultAgeLabel(y * 12), months: y * 12),
  ];
}

// ── Página de detalle ──────────────────────────────────────────────────────
class AnimalDetailPage extends ConsumerStatefulWidget {
  final AnimalEntity animal;

  const AnimalDetailPage({super.key, required this.animal});

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
  _AgeOption? _selectedAgeOption;

  /// Imagen nueva seleccionada — se sube al guardar
  File? _newImage;

  final _picker = ImagePicker();
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _currentAnimal = widget.animal;
    _resetEditState();
  }

  void _resetEditState() {
    _nameController = TextEditingController(text: _currentAnimal.name);
    _weightController = TextEditingController(
        text: _currentAnimal.weight != null ? '${_currentAnimal.weight}' : '');
    _selectedBreedName = _currentAnimal.breed;
    final ageOptions = _buildAgeOptions();
    _selectedAgeOption = ageOptions.firstWhere(
      (ageOption) => ageOption.months == _currentAnimal.age,
      orElse: () =>
          _AgeOption(label: _currentAnimal.ageLabel, months: _currentAnimal.age),
    );
    _newImage = null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // ── Navegar al home ────────────────────────────────────────────────────
  void _goHome() =>
      Navigator.of(context).popUntil((route) => route.isFirst);

  // ── Picker de imagen (funciona tanto en vista como en edición) ─────────
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _newImage = File(picked.path));
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _handle(),
              ListTile(
                leading: const Icon(Icons.camera_alt,
                    color: Color(0xFF2E7D32)),
                title: Text(AppStrings.t('take_photo')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: Color(0xFF2E7D32)),
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

  // ── Selector de raza ───────────────────────────────────────────────────
  void _showBreedSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, sc) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _handle(),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
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
                  controller: sc,
                  itemCount: _cattleBreeds.length,
                  itemBuilder: (_, i) {
                    final breed = _cattleBreeds[i];
                    final isSelected = breed == _selectedBreedName;
                    return ListTile(
                      title: Text(breed),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF2E7D32))
                          : null,
                      tileColor: isSelected ? const Color(0xFFE8F5E9) : null,
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

  // ── Selector de edad ───────────────────────────────────────────────────
  void _showAgeSelector() {
    final ageOptions = _buildAgeOptions();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, sc) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _handle(),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
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
                  controller: sc,
                  itemCount: ageOptions.length,
                  itemBuilder: (_, i) {
                    final ageOption = ageOptions[i];
                    final isSelected =
                        ageOption.months == _selectedAgeOption?.months;
                    return ListTile(
                      title: Text(ageOption.label),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF2E7D32))
                          : null,
                      tileColor: isSelected ? const Color(0xFFE8F5E9) : null,
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

  // ── Guardar edición ────────────────────────────────────────────────────
  Future<void> _saveEdit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack(AppStrings.t('required_field'));
      return;
    }
    setState(() => _isSaving = true);

    try {
      final weightText = _weightController.text.trim().replaceAll(',', '.');
      final double? weight =
          weightText.isNotEmpty ? double.tryParse(weightText) : null;

      // Sube la imagen nueva directamente a Supabase si la hay
      String? uploadedProfileImageUrl = _currentAnimal.profileImageUrl;
      if (_newImage != null) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          uploadedProfileImageUrl =
              await _storageService.uploadAnimalImage(_newImage!, user.id);
        }
      }

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
        profileImageUrl: uploadedProfileImageUrl,
        createdAt: _currentAnimal.createdAt,
        updatedAt: DateTime.now(),
      );

      // Actualiza en Supabase y Hive
      await ref.read(animalRepositoryProvider).updateAnimal(updatedAnimal);

      // También actualiza profile_image_url directamente en Supabase
      // para que otros dispositivos lo vean inmediatamente
      if (_newImage != null && uploadedProfileImageUrl != null) {
        await Supabase.instance.client
            .from('animals')
            .update({'profile_image_url': uploadedProfileImageUrl})
            .eq('id', _currentAnimal.id);
      }

      if (!mounted) return;

      setState(() {
        _currentAnimal = updatedAnimal;
        _isEditing = false;
        _isSaving = false;
        _newImage = null;
      });
      _resetEditState();
      ref.invalidate(animalRepositoryProvider);
      _snack(AppStrings.t('saved_ok'));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _snack('${AppStrings.t("save_error")}: $e');
    }
  }

  // ── Eliminar animal ────────────────────────────────────────────────────
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppStrings.t('delete_animal'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(AppStrings.t('delete_animal_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.t('cancel')),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(animalRepositoryProvider).deleteAnimal(_currentAnimal.id);
      ref.invalidate(animalRepositoryProvider);
      if (mounted) {
        _snack(AppStrings.t('animal_deleted'));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack(AppStrings.t('delete_error'));
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  Widget _handle() => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2)),
      );

  // ── BUILD ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? AppStrings.t('edit_animal')
            : _currentAnimal.name),
        actions: [
          // Icono de casa — siempre visible
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
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent),
              tooltip: AppStrings.t('delete_animal'),
              onPressed: _confirmDelete,
            ),
          ] else ...[
            TextButton(
              onPressed: () => setState(() {
                _isEditing = false;
                _resetEditState();
              }),
              child: Text(AppStrings.t('cancel'),
                  style: const TextStyle(color: Colors.white)),
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
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(AppStrings.t('save_changes')),
            )
          : null,

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Foto de perfil ─────────────────────────────────────
            // GestureDetector siempre activo — funciona en vista y edición
            _buildProfileImage(isDark),
            const SizedBox(height: 20),

            if (_isEditing)
              _buildEditForm()
            else
              _buildViewMode(),
          ],
        ),
      ),
    );
  }

  // ── Foto de perfil ─────────────────────────────────────────────────────
  Widget _buildProfileImage(bool isDark) {
    // Determina qué imagen mostrar
    Widget imageContent;
    if (_newImage != null) {
      // Imagen recién seleccionada (antes de guardar)
      imageContent = Image.file(_newImage!,
          width: double.infinity, height: 220, fit: BoxFit.cover);
    } else if (_currentAnimal.profileImageUrl != null &&
        _currentAnimal.profileImageUrl!.isNotEmpty) {
      // Imagen guardada en Supabase
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

    // Overlay diferente según modo
    final overlayColor = _isEditing
        ? Colors.black.withValues(alpha: 0.40)
        : Colors.black.withValues(alpha: 0.28);

    final overlayIcon =
        _isEditing ? Icons.camera_alt : Icons.add_a_photo_outlined;
    final overlayText = _isEditing
        ? AppStrings.t('change_photo')
        : AppStrings.t('add_photo');

    // La foto SIEMPRE es tappable para cambiarla
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageContent,
          ),
          // Overlay con icono — visible siempre para indicar que es tappable
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
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultImageAsset() => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          AppStrings.t('animal_default_image'),
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
        ),
      );

  // ── Modo VISTA ─────────────────────────────────────────────────────────
  Widget _buildViewMode() {
    final weightText = _currentAnimal.weight != null
        ? '${_currentAnimal.weight} ${AppStrings.t("kg")}'
        : AppStrings.t('weight_no_data');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(Icons.pets, AppStrings.t('breed_label'),
            _currentAnimal.breed),
        _infoRow(
          Icons.cake,
          AppStrings.t('age_label'),
          _currentAnimal.ageLabel.isNotEmpty
              ? _currentAnimal.ageLabel
              : AnimalEntity.defaultAgeLabel(_currentAnimal.age),
        ),
        _infoRow(Icons.monitor_weight_outlined,
            AppStrings.t('weight_label'), weightText),
        if (_currentAnimal.temperature != null)
          _infoRow(Icons.thermostat, AppStrings.t('temperature_label'),
              '${_currentAnimal.temperature} °C'),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.medical_services),
            label: Text(AppStrings.t('view_medical_history')),
            onPressed: () async {
              // Esperamos el resultado: MedicalHistoryPage puede devolver
              // un AnimalEntity actualizado si se cambió la foto desde ahí.
              final updated = await Navigator.push<AnimalEntity>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MedicalHistoryPage(animal: _currentAnimal),
                ),
              );
              // Si el historial clínico actualizó la foto, la reflejamos aquí
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2E7D32), size: 20),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 15),
                overflow: TextOverflow.visible),
          ),
        ],
      ),
    );
  }

  // ── Modo EDICIÓN ───────────────────────────────────────────────────────
  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9 ]')),
          ],
          decoration: InputDecoration(
            labelText: '${AppStrings.t("name")} *',
            prefixIcon:
                const Icon(Icons.pets, color: Color(0xFF2E7D32)),
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
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
          decoration: InputDecoration(
            labelText:
                '${AppStrings.t("weight")} — ${AppStrings.t("optional")}',
            hintText: AppStrings.t('weight_hint'),
            prefixIcon: const Icon(Icons.monitor_weight_outlined,
                color: Color(0xFF2E7D32)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedValue ?? label,
                style: TextStyle(
                  fontSize: 16,
                  color: selectedValue != null
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Colors.grey.shade600,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}
