import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../animals/domain/entities/animal_entity.dart';
import '../../../animals/presentation/providers/animal_provider.dart';
import '../providers/medical_provider.dart';
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
  late AnimalEntity _animal;

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
  }

  Future<void> _pickProfileImage() async {
    final isOnline = await ConnectivityService.checkAndNotify(
      context,
      message: "Necesitas internet para cambiar la foto del animal",
    );
    if (!isOnline) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    if (!mounted) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final url = await _storageService.uploadAnimalImage(
          File(picked.path), user.id);

      await Supabase.instance.client
          .from('animals')
          .update({'profile_image_url': url}).eq('id', _animal.id);

      if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _addRecord() async {
    final isOnline = await ConnectivityService.checkAndNotify(
      context,
      message: "Necesitas internet para agregar registros médicos",
    );
    if (!isOnline) return;
    if (!mounted) return;

    final diagnosisController = TextEditingController();
    File? selectedImage;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
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
              const Text("Nuevo registro médico",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picked = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (picked != null) {
                    setModal(() => selectedImage = File(picked.path));
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
                                size: 40,
                                color: Colors.grey.shade400),
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
        imageUrl = await _storageService.uploadAnimalImage(
            imageFile, user.id);
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

      await ref.read(medicalRepositoryProvider).addRecord(record);

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registro guardado")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _deleteRecord(String recordId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar registro"),
        content: const Text(
            "¿Seguro que deseas eliminar este registro médico?"),
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
    if (!mounted) return;

    try {
      await Supabase.instance.client
          .from('medical_records')
          .delete()
          .eq('id', recordId);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _editRecord(String recordId, String? currentDiagnosis) async {
    final controller =
        TextEditingController(text: currentDiagnosis ?? '');

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
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
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
                        .update(
                            {'diagnosis': controller.text.trim()})
                        .eq('id', recordId);
                    if (!mounted) return;
                    setState(() {});
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")));
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
      appBar: AppBar(title: Text(_animal.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord,
        icon: const Icon(Icons.add),
        label: const Text("Nuevo registro"),
      ),
      body: Column(
        children: [
          // --- Header con foto de perfil ---
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
                        backgroundImage:
                            _animal.profileImageUrl != null &&
                                    _animal.profileImageUrl!.isNotEmpty
                                ? NetworkImage(_animal.profileImageUrl!)
                                : null,
                        child: _animal.profileImageUrl == null ||
                                _animal.profileImageUrl!.isEmpty
                            ? const Icon(Icons.set_meal,
                                size: 40, color: Colors.white)
                            : null,
                      ),
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
                          fontWeight: FontWeight.bold),
                    ),
                    Text(_animal.breed,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    Text(
                      "${_animal.age} años",
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
                  return const Center(
                      child: Text("Error al cargar registros"));
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
                        const Text("No hay registros médicos aún",
                            style: TextStyle(color: Colors.grey)),
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
                                      fontSize: 12, color: Colors.grey),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      size: 18, color: Colors.blue),
                                  onPressed: () => _editRecord(
                                      record.id, record.diagnosis),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      size: 18, color: Colors.red),
                                  onPressed: () =>
                                      _deleteRecord(record.id),
                                ),
                              ],
                            ),
                            if (record.imageUrl != null &&
                                record.imageUrl!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  record.imageUrl!,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            const Text("Diagnóstico:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(record.diagnosis ?? "Sin diagnóstico"),
                            const SizedBox(height: 8),
                            const Text("Resultado IA:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(record.aiResult ?? "Sin resultado de IA"),
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