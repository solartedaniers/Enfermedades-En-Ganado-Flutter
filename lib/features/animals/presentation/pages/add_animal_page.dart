import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/animal_entity.dart';
import '../providers/animal_provider.dart';

class AddAnimalPage extends ConsumerStatefulWidget {
  const AddAnimalPage({super.key});

  @override
  ConsumerState<AddAnimalPage> createState() => _AddAnimalPageState();
}

class _AddAnimalPageState extends ConsumerState<AddAnimalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _weightController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _storageService = StorageService();
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _symptomsController.dispose();
    _weightController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked =
        await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt,
                    color: Color(0xFF2E7D32)),
                title: Text(AppStrings.t("take_photo")),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: Color(0xFF2E7D32)),
                title: Text(AppStrings.t("choose_gallery")),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t("error_no_session"))),
        );
        return;
      }

      // Sube la foto para diagnóstico IA
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadAnimalImage(
            _selectedImage!, user.id);
      }

      final animal = AnimalEntity(
        id: const Uuid().v4(),
        userId: user.id,
        name: _nameController.text.trim(),
        breed: _breedController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        symptoms: _symptomsController.text.trim(),
        weight: _weightController.text.trim().isEmpty
            ? null
            : double.tryParse(_weightController.text.trim()),
        temperature: _temperatureController.text.trim().isEmpty
            ? null
            : double.tryParse(_temperatureController.text.trim()),
        imageUrl: imageUrl, // foto para IA
        profileImageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(animalRepositoryProvider).addAnimal(animal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t("saved_ok"))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("${AppStrings.t("save_error")}: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t("add_animal"))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- Selector de foto para IA ---
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!,
                            fit: BoxFit.cover)
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              // imagen icon.webp de fondo
                              Image.asset(
                                AppStrings.t(
                                    "animal_default_image"),
                                fit: BoxFit.cover,
                              ),
                              // overlay semitransparente
                              Container(
                                color:
                                    Colors.black.withValues(alpha: 0.45),
                              ),
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo,
                                      size: 44,
                                      color: Colors.white),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppStrings.t("add_photo"),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight:
                                            FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Foto para diagnóstico IA",
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.8),
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).scale(
                    begin: const Offset(0.95, 0.95),
                  ),
              const SizedBox(height: 24),

              _buildField(
                controller: _nameController,
                label: "${AppStrings.t("name")} *",
                icon: Icons.pets,
                validator: (v) => v == null || v.isEmpty
                    ? AppStrings.t("required_field")
                    : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _breedController,
                label: "${AppStrings.t("breed")} *",
                icon: Icons.category_outlined,
                validator: (v) => v == null || v.isEmpty
                    ? AppStrings.t("required_field")
                    : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _ageController,
                label: "${AppStrings.t("age")} *",
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return AppStrings.t("required_field");
                  }
                  if (int.tryParse(v) == null) {
                    return AppStrings.t("invalid_number");
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _symptomsController,
                label: "${AppStrings.t("symptoms")} *",
                icon: Icons.sick_outlined,
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty
                    ? AppStrings.t("required_field")
                    : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _weightController,
                label:
                    "${AppStrings.t("weight")} — ${AppStrings.t("optional")}",
                icon: Icons.monitor_weight_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _temperatureController,
                label:
                    "${AppStrings.t("temperature")} — ${AppStrings.t("optional")}",
                icon: Icons.thermostat_outlined,
                keyboardType: TextInputType.number,
              ),
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
                              strokeWidth: 2),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon, color: const Color(0xFF2E7D32)),
      ),
      validator: validator,
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.03);
  }
}