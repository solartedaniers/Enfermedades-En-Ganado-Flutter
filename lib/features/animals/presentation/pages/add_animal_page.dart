import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
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
        imageUrl: null,
        profileImageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(animalRepositoryProvider);
      await repo.addAnimal(animal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t("saved_ok"))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppStrings.t("save_error")}: $e")),
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
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- Ícono de ganado en lugar de huella ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.set_meal,
                        size: 64, color: Colors.green.shade400),
                    const SizedBox(height: 8),
                    Text(
                      "La foto para diagnóstico IA\nse agrega desde el historial",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.green.shade700, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                    labelText: "${AppStrings.t("name")} *"),
                validator: (v) => v == null || v.isEmpty
                    ? AppStrings.t("required_field")
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _breedController,
                decoration: InputDecoration(
                    labelText: "${AppStrings.t("breed")} *"),
                validator: (v) => v == null || v.isEmpty
                    ? AppStrings.t("required_field")
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                    labelText: "${AppStrings.t("age")} *"),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _symptomsController,
                decoration: InputDecoration(
                    labelText: "${AppStrings.t("symptoms")} *"),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty
                    ? AppStrings.t("required_field")
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText:
                      "${AppStrings.t("weight")} — ${AppStrings.t("optional")}",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _temperatureController,
                decoration: InputDecoration(
                  labelText:
                      "${AppStrings.t("temperature")} — ${AppStrings.t("optional")}",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : Text(AppStrings.t("save")),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}