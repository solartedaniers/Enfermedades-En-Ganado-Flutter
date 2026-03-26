import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/animal_entity.dart';
import '../providers/animal_provider.dart';

// ── Razas de ganado disponibles ────────────────────────────────────────────
const List<String> _cattleBreeds = [
  'Aberdeen Angus', 'Beefmaster', 'Belgian Blue', 'Blonde d\'Aquitaine',
  'Bonsmara', 'Brahman', 'Brangus', 'Brown Swiss', 'Charolais', 'Chianina',
  'Criollo', 'Devon', 'Droughtmaster', 'Fleckvieh', 'Gelbvieh', 'Gir',
  'Guzerá', 'Hereford', 'Holstein Friesian', 'Jersey', 'Limousin', 'Longhorn',
  'Maine-Anjou', 'Marchigiana', 'Montbéliarde', 'Murray Grey', 'Nelore',
  'Normande', 'Piedmontese', 'Pinzgauer', 'Red Angus', 'Red Poll',
  'Romosinuano', 'Sahiwal', 'Salorn', 'Santa Gertrudis', 'Senepol',
  'Shorthorn', 'Simmental', 'Taurus', 'Zebu (Cebú)',
];

// ── Opciones de edad ───────────────────────────────────────────────────────
List<_AgeOption> _buildAgeOptions(BuildContext context) {
  final monthLabel  = AppStrings.t("month");
  final monthsLabel = AppStrings.t("months");
  final yearLabel   = AppStrings.t("year");
  final yearsLabel  = AppStrings.t("years");

  return [
    _AgeOption(label: "1 $monthLabel", months: 1),
    for (int m = 2; m <= 11; m++)
      _AgeOption(label: "$m $monthsLabel", months: m),
    _AgeOption(label: "1 $yearLabel", months: 12),
    for (int y = 2; y <= 25; y++)
      _AgeOption(label: "$y $yearsLabel", months: y * 12),
  ];
}

class _AgeOption {
  final String label;
  final int months;
  const _AgeOption({required this.label, required this.months});
}

class AddAnimalPage extends ConsumerStatefulWidget {
  const AddAnimalPage({super.key});

  @override
  ConsumerState<AddAnimalPage> createState() => _AddAnimalPageState();
}

class _AddAnimalPageState extends ConsumerState<AddAnimalPage> {
  final _formKey          = GlobalKey<FormState>();
  final _nameController   = TextEditingController();
  final _weightController = TextEditingController();
  final _picker           = ImagePicker();

  File?       _selectedImage;
  String?     _selectedBreedName;
  _AgeOption? _selectedAgeOption;
  bool        _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  void _showImageSourceDialog() {
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
                leading: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
                title: Text(AppStrings.t("take_photo")),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF2E7D32)),
                title: Text(AppStrings.t("choose_gallery")),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showBreedSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.9,
        expand: false,
        builder: (_, sc) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _sheetHandle(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(AppStrings.t("select_breed"),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
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
                          ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32))
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

  void _showAgeSelector() {
    final ageOptions = _buildAgeOptions(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55, minChildSize: 0.35, maxChildSize: 0.85,
        expand: false,
        builder: (_, sc) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _sheetHandle(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(AppStrings.t("select_age"),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
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
                          ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32))
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

  // ── MÉTODO SUBMIT ACTUALIZADO Y BLINDADO ──────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBreedName == null || _selectedAgeOption == null) {
      _showSnack(AppStrings.t("required_field"));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception(AppStrings.t("error_no_session"));
      }

      // 1. Manejo seguro de la imagen
      final String? localPath = _selectedImage?.path;

      // 2. Parsing de peso (acepta coma y punto)
      double? weight;
      final wt = _weightController.text.trim().replaceAll(',', '.');
      if (wt.isNotEmpty) weight = double.tryParse(wt);

      final now = DateTime.now();

      // 3. Creación robusta de la entidad (Campos obligatorios garantizados)
      final animal = AnimalEntity(
        id: const Uuid().v4(),
        userId: user.id,
        name: _nameController.text.trim(),
        breed: _selectedBreedName!,
        age: _selectedAgeOption!.months,
        ageLabel: _selectedAgeOption!.label,
        symptoms: '', // Nunca nulo
        weight: weight,
        temperature: null,
        imageUrl: null,
        profileImageUrl: null,
        createdAt: now,
        updatedAt: now,
      );

      // 4. Delegamos la lógica de sincronización e imagen al repositorio
      await ref.read(animalRepositoryProvider).addAnimal(
        animal,
        localImagePath: localPath,
      );

      if (mounted) {
        _showSnack(AppStrings.t("saved_ok"));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnack("${AppStrings.t("save_error")}: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Widget _sheetHandle() => Container(
    width: 40, height: 4,
    margin: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t("add_animal"))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity, height: 180,
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
                                AppStrings.t("animal_default_image"),
                                fit: BoxFit.cover,
                              ),
                              Container(color: Colors.black.withValues(alpha: 0.45)),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo, size: 44, color: Colors.white),
                                  const SizedBox(height: 8),
                                  Text(AppStrings.t("add_photo"),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(AppStrings.t("photo_subtitle"),
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: 24),

              // Nombre
              TextFormField(
                controller: _nameController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9 ]')),
                ],
                decoration: InputDecoration(
                  labelText: "${AppStrings.t("name")} *",
                  prefixIcon: const Icon(Icons.pets, color: Color(0xFF2E7D32)),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? AppStrings.t("required_field") : null,
              ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.03),
              const SizedBox(height: 14),

              // Raza
              _buildSelector(
                label: "${AppStrings.t("breed")} *",
                value: _selectedBreedName,
                icon:  Icons.category_outlined,
                onTap: _showBreedSelector,
              ),
              const SizedBox(height: 14),

              // Edad
              _buildSelector(
                label: "${AppStrings.t("age")} *",
                value: _selectedAgeOption?.label,
                icon:  Icons.cake_outlined,
                onTap: _showAgeSelector,
              ),
              const SizedBox(height: 14),

              // Peso
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                decoration: InputDecoration(
                  labelText: "${AppStrings.t("weight")} — ${AppStrings.t("optional")}",
                  hintText: AppStrings.t("weight_hint"),
                  prefixIcon: const Icon(Icons.monitor_weight_outlined, color: Color(0xFF2E7D32)),
                  suffixText: AppStrings.t("kg"),
                ),
              ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.03),
              const SizedBox(height: 28),

              // Botón guardar
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(AppStrings.t("save")),
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
            Icon(icon, color: const Color(0xFF2E7D32)),
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
