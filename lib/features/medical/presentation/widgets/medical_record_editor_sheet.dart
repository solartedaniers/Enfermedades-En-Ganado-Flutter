import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_theme.dart';
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

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (widget.allowImage) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: appColors.inputBorderLight),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: appColors.inputBorderLight,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.t('medical_ai_photo_hint'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: appColors.mutedForeground,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _diagnosisController,
            decoration: InputDecoration(
              labelText: AppStrings.t('medical_diagnosis_observations'),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
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
