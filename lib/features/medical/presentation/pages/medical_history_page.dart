import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../animals/domain/entities/animal_entity.dart';
import '../../../animals/presentation/providers/animal_provider.dart';
import '../providers/medical_provider.dart';
import '../../domain/entities/medical_record_entity.dart';
import '../../data/models/medical_record_model.dart';

class MedicalHistoryPage extends ConsumerStatefulWidget {
  final AnimalEntity animal;

  const MedicalHistoryPage({
    super.key,
    required this.animal,
  });

  @override
  ConsumerState<MedicalHistoryPage> createState() =>
      _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends ConsumerState<MedicalHistoryPage> {
  final _storageService = StorageService();
  final _picker = ImagePicker();
  bool _uploadingProfileImage = false;
  late AnimalEntity _animal;

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
  }

  // Sube foto de perfil del animal
  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _uploadingProfileImage = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final file = File(picked.path);
      final url = await _storageService.uploadAnimalImage(file, user.id);

      // Actualiza en Supabase
      await Supabase.instance.client
          .from('animals')
          .update({'profile_image_url': url})
          .eq('id', _animal.id);

      setState(() {
        _animal = AnimalEntity(
          id: _animal.id,
          userId: _animal.userId,
          name: _animal.name,
          breed: _animal.breed,
          age: _animal.age,
          symptoms: _animal.symptoms,
          weight: _animal.weight,
          temperature: _animal.temperature,
          imageUrl: _animal.imageUrl,
          profileImageUrl: url,
          createdAt: _animal.createdAt,
          updatedAt: DateTime.now(),
        );
      });

      ref.invalidate(animalRepositoryProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error subiendo imagen: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingProfileImage = false);
    }
  }

  // Agrega nuevo registro médico con imagen para IA
  Future<void> _addRecord() async {
    final diagnosisController = TextEditingController();
    File? selectedImage;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Nuevo registro médico",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Imagen para IA
              GestureDetector(
                onTap: () async {
                  final picked = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (picked != null) {
                    setModalState(
                        () => selectedImage = File(picked.path));
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(selectedImage!,
                              fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              "Foto para diagnóstico IA\n(toca para tomar)",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: diagnosisController,
                decoration: const InputDecoration(
                  labelText: "Observaciones / Diagnóstico",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _saveRecord(
                      diagnosis: diagnosisController.text.trim(),
                      imageFile: selectedImage,
                    );
                  },
                  child: const Text("Guardar registro"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveRecord({
    required String diagnosis,
    File? imageFile,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      String? imageUrl;
      if (imageFile != null) {
        imageUrl =
            await _storageService.uploadAnimalImage(imageFile, user.id);
      }

      final record = MedicalRecordModel(
        id: const Uuid().v4(),
        animalId: _animal.id,
        userId: user.id,
        diagnosis: diagnosis.isEmpty ? null : diagnosis,
        aiResult: null,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      final repo = ref.read(medicalRepositoryProvider);
      await repo.addRecord(record);

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registro guardado")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _deleteRecord(String recordId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar registro"),
        content:
            const Text("¿Seguro que deseas eliminar este registro médico?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('medical_records')
          .delete()
          .eq('id', recordId);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _editRecord(MedicalRecordEntity record) async {
    final controller =
        TextEditingController(text: record.diagnosis ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Editar registro",
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Diagnóstico / Observaciones",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await Supabase.instance.client
                        .from('medical_records')
                        .update({'diagnosis': controller.text.trim()})
                        .eq('id', record.id);
                    if (mounted) setState(() {});
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")));
                    }
                  }
                },
                child: const Text("Guardar cambios"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(medicalRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_animal.name),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord,
        icon: const Icon(Icons.add),
        label: const Text("Nuevo registro"),
      ),
      body: Column(
        children: [
          // --- Header con foto de perfil del animal ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white24,
                        backgroundImage: _animal.profileImageUrl != null
                            ? NetworkImage(_animal.profileImageUrl!)
                            : null,
                        child: _animal.profileImageUrl == null
                            ? Icon(Icons.set_meal,
                                size: 40, color: Colors.white)
                            : null,
                      ),
                      if (_uploadingProfileImage)
                        const Positioned.fill(
                          child: CircularProgressIndicator(
                              color: Colors.white),
                        )
                      else
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 14, color: Color(0xFF2E7D32)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _animal.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _animal.breed,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      "${_animal.age} ${AppStrings.t("years")}",
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Lista de registros ---
          Expanded(
            child: FutureBuilder(
              future: repo.getRecords(_animal.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          "${AppStrings.t("load_error")}: ${snapshot.error}"));
                }

                final records = snapshot.data ?? [];

                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medical_services_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(AppStrings.t("no_records"),
                            style:
                                const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(
                          "Toca + para agregar un registro",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  "${record.createdAt.day}/${record.createdAt.month}/${record.createdAt.year}",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey),
                                ),
                                const Spacer(),
                                // Editar
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      size: 18, color: Colors.blue),
                                  onPressed: () => _editRecord(record),
                                ),
                                // Eliminar
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      size: 18, color: Colors.red),
                                  onPressed: () =>
                                      _deleteRecord(record.id),
                                ),
                              ],
                            ),

                            // Imagen para IA si existe
                            if ((record as dynamic).imageUrl != null) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  (record as dynamic).imageUrl!,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),
                            Text(
                              "${AppStrings.t("diagnosis_label")}:",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(record.diagnosis ??
                                AppStrings.t("no_diagnosis")),
                            const SizedBox(height: 8),
                            Text(
                              "${AppStrings.t("ai_result")}:",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(record.aiResult ??
                                AppStrings.t("no_ai_result")),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}