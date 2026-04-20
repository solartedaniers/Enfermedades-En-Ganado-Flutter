import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/app_strings.dart';

class MedicalRecordDraft {
  final String diagnosis;
  final File? imageFile;

  const MedicalRecordDraft({
    required this.diagnosis,
    required this.imageFile,
  });
}

class MedicalRecordEditorSheet extends StatefulWidget {
  final String title;
  final String buttonLabel;
  final String initialDiagnosis;
  final bool allowImage;

  const MedicalRecordEditorSheet({
    super.key,
    required this.title,
    required this.buttonLabel,
    this.initialDiagnosis = '',
    this.allowImage = false,
  });

  @override
  State<MedicalRecordEditorSheet> createState() => _MedicalRecordEditorSheetState();
}

class _MedicalRecordEditorSheetState extends State<MedicalRecordEditorSheet> {
  final _picker = ImagePicker();
  late final TextEditingController _diagnosisController;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _diagnosisController = TextEditingController(text: widget.initialDiagnosis);
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    setState(() => _selectedImage = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.large,
        right: AppSizes.large,
        top: AppSizes.large,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: AppTextStyles.sectionTitle(theme),
          ),
          if (widget.allowImage) ...[
            const SizedBox(height: AppSizes.large),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: AppSizes.medicalPreviewHeight,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSizes.medium),
                  border: Border.all(color: appColors.inputBorderLight),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.medium),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: AppIconSizes.xLarge,
                            color: appColors.inputBorderLight,
                          ),
                          const SizedBox(height: AppSizes.small),
                          Text(
                            AppStrings.t('medical_ai_photo_hint'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: appColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
          const SizedBox(height: AppSizes.medium),
          TextField(
            controller: _diagnosisController,
            decoration: InputDecoration(
              labelText: AppStrings.t('medical_diagnosis_observations'),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: AppSizes.large),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(
                  MedicalRecordDraft(
                    diagnosis: _diagnosisController.text.trim(),
                    imageFile: _selectedImage,
                  ),
                );
              },
              child: Text(widget.buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
