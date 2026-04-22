import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../animals/domain/entities/animal_entity.dart';
import '../../../animals/presentation/providers/animal_provider.dart';
import '../../data/models/medical_record_model.dart';
import '../providers/medical_provider.dart';
import '../widgets/animal_medical_header.dart';
import '../widgets/medical_record_card.dart';
import '../widgets/medical_record_editor_sheet.dart';

class MedicalHistoryPage extends ConsumerStatefulWidget {
  final AnimalEntity animal;

  const MedicalHistoryPage({super.key, required this.animal});

  @override
  ConsumerState<MedicalHistoryPage> createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends ConsumerState<MedicalHistoryPage> {
  final _picker = ImagePicker();
  late AnimalEntity _animal;

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
  }

  void _goHome() => Navigator.of(context).popUntil((route) => route.isFirst);

  Future<void> _pickProfileImage() async {
    final isOnline = await ConnectivityService.checkAndNotify(
      context,
      message: AppStrings.t('medical_need_internet_change_photo'),
    );
    if (!isOnline || !mounted) {
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0),
      builder: (_) => const _MedicalImageSourceSheet(),
    );

    if (source == null || !mounted) {
      return;
    }

    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null || !mounted) {
      return;
    }

    try {
      final updatedAnimal = _animal.copyWith(updatedAt: DateTime.now());
      await ref.read(animalRepositoryProvider).updateAnimal(
            updatedAnimal,
            localImagePath: picked.path,
          );
      final refreshedAnimals =
          await ref.read(animalRepositoryProvider).getAnimals();
      final refreshedAnimal = refreshedAnimals.firstWhere(
        (item) => item.id == _animal.id,
        orElse: () => updatedAnimal,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _animal = refreshedAnimal;
      });
      refreshAnimals(ref);
      _showSnack(AppStrings.t('medical_photo_updated'));
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnack('${AppStrings.t("unexpected_error")}: $error');
    }
  }

  Future<void> _openRecordSheet() async {
    final isOnline = await ConnectivityService.checkAndNotify(
      context,
      message: AppStrings.t('medical_need_internet_add_record'),
    );
    if (!isOnline || !mounted) {
      return;
    }

    final draft = await showModalBottomSheet<MedicalRecordDraft>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MedicalRecordEditorSheet(
        title: AppStrings.t('medical_new_record'),
        buttonLabel: AppStrings.t('medical_save_record'),
        allowImage: true,
      ),
    );

    if (draft == null) {
      return;
    }

    await _saveRecord(diagnosis: draft.diagnosis, imageFile: draft.imageFile);
  }

  Future<void> _saveRecord({
    required String diagnosis,
    File? imageFile,
  }) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        return;
      }

      String? imageUrl;
      if (imageFile != null) {
        final storageService = ref.read(storageServiceProvider);
        imageUrl = await storageService.uploadAnimalImage(imageFile, userId);
      }

      final record = MedicalRecordModel(
        id: const Uuid().v4(),
        animalId: _animal.id,
        userId: userId,
        diagnosis: diagnosis.isEmpty ? null : diagnosis,
        aiResult: null,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      await ref.read(medicalRepositoryProvider).addRecord(record);

      if (!mounted) {
        return;
      }

      setState(() {});
      _showSnack(AppStrings.t('medical_record_saved'));
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnack('${AppStrings.t("unexpected_error")}: $error');
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
            child: Text(
              AppStrings.t('delete'),
              style: TextStyle(color: context.appColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) {
      return;
    }

    try {
      await ref.read(medicalRepositoryProvider).deleteRecord(recordId);

      if (!mounted) {
        return;
      }

      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnack('${AppStrings.t("unexpected_error")}: $error');
    }
  }

  Future<void> _editRecord(String recordId, String? currentDiagnosis) async {
    final draft = await showModalBottomSheet<MedicalRecordDraft>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MedicalRecordEditorSheet(
        title: AppStrings.t('medical_edit_record'),
        buttonLabel: AppStrings.t('save_changes'),
        initialDiagnosis: currentDiagnosis ?? '',
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    try {
      await ref.read(medicalRepositoryProvider).updateRecord(
            recordId: recordId,
            diagnosis: draft.diagnosis,
          );

      if (!mounted) {
        return;
      }

      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnack('${AppStrings.t("unexpected_error")}: $error');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animalAsync = ref.watch(animalByIdProvider(_animal.id));
    final latestAnimal = animalAsync.valueOrNull;
    if (latestAnimal != null && latestAnimal != _animal) {
      _animal = latestAnimal;
    }

    final repository = ref.watch(medicalRepositoryProvider);
    final appColors = context.appColors;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_animal);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_animal.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: AppStrings.t('go_home'),
              onPressed: _goHome,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openRecordSheet,
          icon: const Icon(Icons.add),
          label: Text(AppStrings.t('medical_new_record')),
        ),
        body: Column(
          children: [
            AnimalMedicalHeader(
              animal: _animal,
              onAvatarTap: _pickProfileImage,
            ),
            Expanded(
              child: FutureBuilder(
                future: repository.getRecords(_animal.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(AppStrings.t('medical_load_records_error')),
                    );
                  }

                  final records = snapshot.data ?? [];

                  if (records.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            size: AppSizes.emptyStateIcon,
                            color: appColors.inputBorderLight,
                          ),
                          const SizedBox(height: AppSizes.large),
                          Text(
                            AppStrings.t('no_records'),
                            style: AppTextStyles.bodyMuted(
                              Theme.of(context),
                              appColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: AppSizes.small),
                          Text(
                            AppStrings.t('medical_add_record_hint'),
                            style: AppTextStyles.bodyMuted(
                              Theme.of(context),
                              appColors.inputBorderLight,
                            ),
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

                      return MedicalRecordCard(
                        record: record,
                        onEdit: () => _editRecord(record.id, record.diagnosis),
                        onDelete: () => _deleteRecord(record.id),
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

class _MedicalImageSourceSheet extends StatelessWidget {
  const _MedicalImageSourceSheet();

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.modalHandleWidth,
              height: AppSizes.modalHandleHeight,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: appColors.inputBorderLight,
                borderRadius: BorderRadius.circular(AppSizes.modalHandleRadius),
              ),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: appColors.chipForeground),
              title: Text(AppStrings.t('take_photo')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: appColors.chipForeground),
              title: Text(AppStrings.t('choose_gallery')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: AppSizes.small),
          ],
        ),
      ),
    );
  }
}
