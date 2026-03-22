import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/storage_service.dart';
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

  File? _selectedImage;
  final _picker = ImagePicker();
  final _storageService = StorageService();
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
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80, // comprime un poco para no subir archivos enormes
    );

    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Tomar foto"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Elegir de galería"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
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
          const SnackBar(content: Text("Error: no hay sesión activa")),
        );
        return;
      }

      // Subir imagen si fue seleccionada
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadAnimalImage(
          _selectedImage!,
          user.id,
        );
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
        imageUrl: imageUrl, // 🔥 URL de Supabase Storage
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(animalRepositoryProvider);
      await repo.addAnimal(animal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Animal guardado correctamente")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agregar Animal")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- Selector de imagen ---
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Toca para agregar foto",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Campos del formulario ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nombre *",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(
                  labelText: "Raza *",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: "Edad (años) *",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Campo requerido";
                  if (int.tryParse(v) == null) return "Ingresa un número válido";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _symptomsController,
                decoration: const InputDecoration(
                  labelText: "Síntomas *",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: "Peso (kg) — opcional",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _temperatureController,
                decoration: const InputDecoration(
                  labelText: "Temperatura (°C) — opcional",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // --- Botón guardar ---
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Guardar Animal"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}