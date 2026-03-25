import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/animal_entity.dart';
import '../providers/animal_provider.dart';
import '../../../medical/presentation/pages/medical_history_page.dart';

// ── Razas (misma lista que add_animal_page) ────────────────────────────────
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
class _AgeOption {
  final String label;
  final int months;
  const _AgeOption({required this.label, required this.months});
}

List<_AgeOption> _buildAgeOptions() {
  return [
    _AgeOption(label: AnimalEntity.defaultAgeLabel(1), months: 1),
    for (int m = 2; m <= 11; m++)
      _AgeOption(label: AnimalEntity.defaultAgeLabel(m), months: m),
    for (int y = 1; y <= 25; y++)
      _AgeOption(label: AnimalEntity.defaultAgeLabel(y * 12), months: y * 12),
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
  // Estado editable
  late AnimalEntity _current;
  bool _isEditing = false;
  bool _isSaving = false;

  // Controladores de edición
  late TextEditingController _nameCtrl;
  late TextEditingController _weightCtrl;
  String? _editBreed;
  _AgeOption? _editAge;
  File? _newImage; // imagen nueva seleccionada en edición
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _current = widget.animal;
    _resetEditState();
  }

  void _resetEditState() {
    _nameCtrl = TextEditingController(text: _current.name);
    _weightCtrl = TextEditingController(
        text: _current.weight != null ? '${_current.weight}' : '');
    _editBreed = _current.breed;
    final opts = _buildAgeOptions();
    _editAge = opts.firstWhere(
      (o) => o.months == _current.age,
      orElse: () => _AgeOption(
          label: _current.ageLabel, months: _current.age),
    );
    _newImage = null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // ── Navegar al home ────────────────────────────────────────────────────
  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ── Seleccionar imagen en edición ──────────────────────────────────────
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
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

  // ── Selector de raza ───────────────────────────────────────────────────
  void _showBreedPicker() {
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
              _handle(),
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
                    final b = _cattleBreeds[i];
                    final sel = b == _editBreed;
                    return ListTile(
                      title: Text(b),
                      trailing: sel ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32)) : null,
                      tileColor: sel ? const Color(0xFFE8F5E9) : null,
                      onTap: () { setState(() => _editBreed = b); Navigator.pop(context); },
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
  void _showAgePicker() {
    final opts = _buildAgeOptions();
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
              _handle(),
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
                  itemCount: opts.length,
                  itemBuilder: (_, i) {
                    final o = opts[i];
                    final sel = o.months == _editAge?.months;
                    return ListTile(
                      title: Text(o.label),
                      trailing: sel ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32)) : null,
                      tileColor: sel ? const Color(0xFFE8F5E9) : null,
                      onTap: () { setState(() => _editAge = o); Navigator.pop(context); },
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
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack(AppStrings.t("required_field")); return;
    }
    setState(() => _isSaving = true);
    try {
      final wt = _weightCtrl.text.trim().replaceAll(',', '.');
      final double? weight = wt.isNotEmpty ? double.tryParse(wt) : null;

      final updated = AnimalEntity(
        id: _current.id,
        userId: _current.userId,
        name: name,
        breed: _editBreed ?? _current.breed,
        age: _editAge?.months ?? _current.age,
        ageLabel: _editAge?.label ?? _current.ageLabel,
        symptoms: _current.symptoms,
        weight: weight,
        temperature: _current.temperature,
        imageUrl: _current.imageUrl,
        profileImageUrl: _current.profileImageUrl,
        createdAt: _current.createdAt,
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(animalRepositoryProvider);
      await repo.addAnimal(
        updated,
        localImagePath: _newImage?.path,
      );

      setState(() {
        _current = updated;
        _isEditing = false;
        _isSaving = false;
      });
      _resetEditState();
      ref.invalidate(animalRepositoryProvider);
      _snack(AppStrings.t("animal_updated"));
    } catch (_) {
      setState(() => _isSaving = false);
      _snack(AppStrings.t("update_error"));
    }
  }

  // ── Eliminar animal ────────────────────────────────────────────────────
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppStrings.t("delete_animal"),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(AppStrings.t("delete_animal_confirm")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.t("cancel")),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.t("delete")),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(animalRepositoryProvider);
      await repo.deleteAnimal(_current.id);
      
      ref.invalidate(animalRepositoryProvider);
      if (mounted) {
        _snack(AppStrings.t("animal_deleted"));
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) _snack(AppStrings.t("delete_error"));
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  Widget _handle() => Container(
    width: 40, height: 4,
    margin: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
        color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
  );

  // ── BUILD ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? AppStrings.t("edit_animal")
            : _current.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: AppStrings.t("go_home"),
            onPressed: _goHome,
          ),
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppStrings.t("edit_animal"),
              onPressed: () => setState(() => _isEditing = true),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: AppStrings.t("delete_animal"),
              onPressed: _confirmDelete,
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                setState(() { _isEditing = false; _resetEditState(); });
              },
              child: Text(AppStrings.t("cancel"),
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
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(AppStrings.t("save_changes")),
            )
          : null,

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileImage(isDark),
            const SizedBox(height: 20),

            if (_isEditing)
              _buildEditForm(isDark, colorScheme)
            else
              _buildViewMode(isDark),
          ],
        ),
      ),
    );
  }

  // ── Foto de perfil ─────────────────────────────────────────────────────
  Widget _buildProfileImage(bool isDark) {
    Widget imageWidget;

    if (_isEditing && _newImage != null) {
      imageWidget = Image.file(_newImage!, width: double.infinity,
          height: 220, fit: BoxFit.cover);
    } else if (_current.profileImageUrl != null &&
        _current.profileImageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        _current.profileImageUrl!,
        width: double.infinity, height: 220, fit: BoxFit.cover,
        // CORRECCIÓN: Se usa _ y __ en lugar de __ y ___ para evitar advertencias
        errorBuilder: (_, _, _) => _defaultImage(),
      );
    } else {
      imageWidget = _defaultImage();
    }

    return GestureDetector(
      onTap: _isEditing ? _showImageSourceDialog : null,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageWidget,
          ),
          if (_isEditing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 36, color: Colors.white),
                    SizedBox(height: 6),
                    Text("Cambiar foto",
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _defaultImage() => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Stack(
      children: [
        Image.asset(AppStrings.t("animal_default_image"),
            width: double.infinity, height: 220, fit: BoxFit.cover),
        if (!_isEditing)
          Container(
            width: double.infinity, height: 220,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, size: 32, color: Colors.white),
                const SizedBox(height: 6),
                Text(AppStrings.t("add_photo"),
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
      ],
    ),
  );

  // ── Modo VISTA ─────────────────────────────────────────────────────────
  Widget _buildViewMode(bool isDark) {
    final weightText = _current.weight != null
        ? "${_current.weight} ${AppStrings.t("kg")}"
        : AppStrings.t("weight_no_data");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(Icons.pets, AppStrings.t("breed_label"), _current.breed),
        _infoRow(Icons.cake, AppStrings.t("age_label"),
            _current.ageLabel.isNotEmpty
                ? _current.ageLabel
                : AnimalEntity.defaultAgeLabel(_current.age)),
        _infoRow(Icons.monitor_weight_outlined,
            AppStrings.t("weight_label"), weightText),
        if (_current.temperature != null)
          _infoRow(Icons.thermostat, AppStrings.t("temperature_label"),
              "${_current.temperature} °C"),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.medical_services),
            label: Text(AppStrings.t("view_medical_history")),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MedicalHistoryPage(animal: _current)),
            ),
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
          Text("$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
  Widget _buildEditForm(bool isDark, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameCtrl,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9 ]')),
          ],
          decoration: InputDecoration(
            labelText: "${AppStrings.t("name")} *",
            prefixIcon: const Icon(Icons.pets, color: Color(0xFF2E7D32)),
          ),
        ),
        const SizedBox(height: 14),

        _selectorField(
          label: AppStrings.t("breed_label"),
          value: _editBreed,
          icon: Icons.category_outlined,
          onTap: _showBreedPicker,
        ),
        const SizedBox(height: 14),

        _selectorField(
          label: AppStrings.t("age_label"),
          value: _editAge?.label,
          icon: Icons.cake_outlined,
          onTap: _showAgePicker,
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _weightCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
          decoration: InputDecoration(
            labelText:
                "${AppStrings.t("weight")} — ${AppStrings.t("optional")}",
            hintText: AppStrings.t("weight_hint"),
            prefixIcon: const Icon(Icons.monitor_weight_outlined,
                color: Color(0xFF2E7D32)),
            suffixText: AppStrings.t("kg"),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _selectorField({
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
                  color: hasValue
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