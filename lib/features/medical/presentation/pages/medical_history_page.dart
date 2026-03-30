import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../animals/domain/entities/animal_entity.dart';
import '../../../animals/presentation/providers/animal_provider.dart';
import '../../../animals/shared/age_label_formatter.dart';
import '../providers/medical_provider.dart';
import '../../data/models/medical_record_model.dart';

class MedicalHistoryPage extends ConsumerStatefulWidget {
  final AnimalEntity animal;

  const MedicalHistoryPage({super.key, required this.animal});

  @override
  ConsumerState<MedicalHistoryPage> createState() =>
      _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends ConsumerState<MedicalHistoryPage> {
  final _picker = ImagePicker();
  late AnimalEntity _animal;

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
  }

  // ── Navegar al home ────────────────────────────────────────────────────
  void _goHome() =>
      Navigator.of(context).popUntil((route) => route.isFirst);

  // ── Cambiar foto de perfil ─────────────────────────────────────────────
  Future<void> _pickProfileImage() async {
    final appColors = context.appColors;

    final isOnline = await ConnectivityService.checkAndNotify(
      context,
      message: AppStrings.t('medical_need_internet_change_photo'),
    );
    if (!isOnline || !mounted) return;

    // Mostrar opciones: cámara o galería
    final source = await showModalBottomSheet<ImageSource>(
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
                    borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: appColors.chipForeground),
                title: Text(AppStrings.t('take_photo')),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading:
                    Icon(Icons.photo_library, color: appColors.chipForeground),
                title: Text(AppStrings.t('choose_gallery')),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picked =
        await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null || !mounted) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final storageService = ref.read(storageServiceProvider);
      final url = await storageService.uploadAnimalImage(
          File(picked.path), user.id);

      // Actualiza en Supabase inmediatamente
      await Supabase.instance.client
          .from('animals')
          .update({'profile_image_url': url}).eq('id', _animal.id);

      if (!mounted) return;

      // Actualiza el estado local para reflejar el cambio sin recargar
      final updatedAnimal = AnimalEntity(
        id: _animal.id,
        userId: _animal.userId,
        name: _animal.name,
        breed: _animal.breed,
        age: _animal.age,
        ageLabel: _animal.ageLabel,
        symptoms: _animal.symptoms,
        weight: _animal.weight,
        temperature: _animal.temperature,
        imageUrl: _animal.imageUrl,
        profileImageUrl: url,
        createdAt: _animal.createdAt,
        updatedAt: DateTime.now(),
      );

      setState(() => _animal = updatedAnimal);

      // Invalida el provider para que la lista y otras pantallas
      // reflejen el cambio al volver
      ref.invalidate(animalRepositoryProvider);

      // Devuelve el animal actualizado al pop para que AnimalDetailPage
      // actualice su estado sin necesidad de recargar toda la lista
      // (se usa cuando el usuario hace pop desde aquí)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('medical_photo_updated'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(
              SnackBar(content: Text('${AppStrings.t("unexpected_error")}: $e')));
    }
  }

  // ── Agregar registro médico ────────────────────────────────────────────
  Future<void> _addRecord() async {
    final isOnline = await ConnectivityService.checkAndNotify(
      context,
      message: AppStrings.t('medical_need_internet_add_record'),
    );
    if (!isOnline || !mounted) return;

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
              Text(
                AppStrings.t('medical_new_record'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
                                size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.t('medical_ai_photo_hint'),
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
                decoration: InputDecoration(
                  labelText: AppStrings.t('medical_diagnosis_observations'),
                  border: const OutlineInputBorder(),
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
                  child: Text(AppStrings.t('medical_save_record')),
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
        final storageService = ref.read(storageServiceProvider);
        imageUrl = await storageService.uploadAnimalImage(
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
        SnackBar(content: Text(AppStrings.t('medical_record_saved'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(
              SnackBar(content: Text('${AppStrings.t("unexpected_error")}: $e')));
    }
  }

  Future<void> _deleteRecord(String recordId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.t('medical_delete_record')),
        content: Text(AppStrings.t('medical_delete_record_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.t('delete'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

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
          .showSnackBar(
              SnackBar(content: Text('${AppStrings.t("unexpected_error")}: $e')));
    }
  }

  Future<void> _editRecord(
      String recordId, String? currentDiagnosis) async {
    final diagnosisController =
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
            Text(AppStrings.t('medical_edit_record'),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: diagnosisController,
              decoration: InputDecoration(
                labelText: AppStrings.t('medical_diagnosis_observations'),
                border: const OutlineInputBorder(),
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
                        .update({'diagnosis': diagnosisController.text.trim()})
                        .eq('id', recordId);
                    if (!mounted) return;
                    setState(() {});
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '${AppStrings.t("unexpected_error")}: $e')));
                  }
                },
                child: Text(AppStrings.t('save_changes')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final repo = ref.watch(medicalRepositoryProvider);

    return PopScope(
      // Al hacer pop, devuelve el animal actualizado a AnimalDetailPage
      // para que refleje inmediatamente cualquier cambio de foto
      onPopInvokedWithResult: (didPop, result) {
        // No hace falta hacer nada extra: Navigator.pop con result lo maneja
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_animal.name),
          actions: [
            // Icono de casa para ir al panel principal
            IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: AppStrings.t('go_home'),
              onPressed: _goHome,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addRecord,
          icon: const Icon(Icons.add),
          label: Text(AppStrings.t('medical_new_record')),
        ),
        body: Column(
          children: [
            // ── Header con foto de perfil, nombre, raza, edad y peso ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [appColors.medicalHeaderStart, appColors.medicalHeaderEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // Avatar tappable para cambiar foto
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white24,
                          backgroundImage: _animal.profileImageUrl !=
                                      null &&
                                  _animal.profileImageUrl!.isNotEmpty
                              ? NetworkImage(_animal.profileImageUrl!)
                              : null,
                          child: _animal.profileImageUrl == null ||
                                  _animal.profileImageUrl!.isEmpty
                              ? const Icon(Icons.pets,
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
                            child: Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: appColors.chipForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Datos del animal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _animal.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _animal.breed,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        // Edad usando ageLabel (no age en meses crudo)
                        Text(
                          _animal.ageLabel.isNotEmpty
                              ? _animal.ageLabel
                              : AgeLabelFormatter.format(_animal.age),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        // Peso — solo si existe
                        if (_animal.weight != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${_animal.weight} ${AppStrings.t("kg")}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Lista de registros médicos ──────────────────────────
            Expanded(
              child: FutureBuilder(
                future: repo.getRecords(_animal.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text(AppStrings.t('medical_load_records_error')));
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
                          Text(AppStrings.t('no_records'),
                              style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.t('medical_add_record_hint'),
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${record.createdAt.day}/${record.createdAt.month}/${record.createdAt.year}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey),
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
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  child: Image.network(
                                    record.imageUrl!,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text('${AppStrings.t("diagnosis_label")}:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(record.diagnosis ??
                                  AppStrings.t('no_diagnosis')),
                              const SizedBox(height: 8),
                              Text('${AppStrings.t("ai_result")}:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(record.aiResult ??
                                  AppStrings.t('no_ai_result')),
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
      ),
    );
  }
}
