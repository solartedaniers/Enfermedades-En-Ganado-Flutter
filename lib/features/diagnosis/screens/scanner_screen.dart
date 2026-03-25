import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/ai/models/diagnosis_request.dart';
import '../../../core/ai/models/diagnosis_response.dart';
import '../../../core/ai/providers/ai_diagnosis_provider.dart';
import '../../../core/utils/app_strings.dart';
import '../../animals/domain/entities/animal_entity.dart';
import '../../animals/presentation/pages/add_animal_page.dart';
import '../../animals/presentation/providers/animal_provider.dart';
import '../../medical/data/models/medical_record_model.dart';
import '../../medical/presentation/providers/medical_provider.dart';

enum _ScannerStep {
  intake,
  camera,
  result,
}

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  static const Color _primaryColor = Color(0xFFBF22DF);
  static const Color _targetColor = Color(0xFF34C759);
  static const double _targetSize = 260;

  final TextEditingController _mainReasonController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();

  late Future<List<AnimalEntity>> _animalsFuture;
  CameraController? _cameraController;
  AnimalEntity? _selectedAnimal;
  DiagnosisReport? _report;
  Uint8List? _capturedImageBytes;
  _ScannerStep _currentStep = _ScannerStep.intake;
  bool _isInitializingCamera = false;
  bool _isSubmitting = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animalsFuture = _loadAnimals();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;

    if (_currentStep != _ScannerStep.camera ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _cameraController = null;
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mainReasonController.dispose();
    _symptomsController.dispose();
    _temperatureController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<List<AnimalEntity>> _loadAnimals() async {
    final repo = ref.read(animalRepositoryProvider);
    final animals = await repo.getAnimals();
    if (_selectedAnimal == null && animals.isNotEmpty) {
      _selectedAnimal = animals.first;
      _prefillFromAnimal(_selectedAnimal!);
    }
    return animals;
  }

  void _prefillFromAnimal(AnimalEntity animal) {
    _temperatureController.text = animal.temperature?.toStringAsFixed(1) ?? '';
    if (_symptomsController.text.trim().isEmpty) {
      _symptomsController.text = animal.symptoms;
    }
  }

  Future<void> _initializeCamera() async {
    if (_currentStep != _ScannerStep.camera || _isSubmitting) return;

    setState(() {
      _isInitializingCamera = true;
      _errorMessage = null;
    });

    try {
      final cameras = await availableCameras();
      CameraDescription? rearCamera;

      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          rearCamera = camera;
          break;
        }
      }

      rearCamera ??= cameras.isNotEmpty ? cameras.first : null;

      if (rearCamera == null) {
        throw CameraException(
          'CameraNotFound',
          AppStrings.t('scanner_camera_unavailable'),
        );
      }

      final previousController = _cameraController;
      final controller = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _cameraController = controller;
      await previousController?.dispose();
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _isInitializingCamera = false;
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _isInitializingCamera = false;
        _errorMessage = _mapCameraError(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isInitializingCamera = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _openCamera() async {
    setState(() {
      _currentStep = _ScannerStep.camera;
      _errorMessage = null;
    });
    await _initializeCamera();
  }

  Future<void> _captureAndAnalyze() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final picture = await controller.takePicture();
      final bytes = await File(picture.path).readAsBytes();
      await _runDiagnosis(imageBytes: bytes);
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _mapCameraError(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _diagnoseWithoutImage() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _runDiagnosis();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _runDiagnosis({Uint8List? imageBytes}) async {
    final service = ref.read(livestockDiagnosisServiceProvider);
    final request = _buildRequest(imageBytes: imageBytes);
    final response = await service.analyze(request);

    if (!mounted) return;

    switch (response.status) {
      case DiagnosisStatus.needsConfiguration:
      case DiagnosisStatus.needsInternet:
      case DiagnosisStatus.needsClinicalQuestion:
      case DiagnosisStatus.needsVisualEvidence:
        _showMessage(response.nextStep.message);
        break;
      case DiagnosisStatus.readyToAnalyze:
        _showMessage(response.nextStep.message);
        break;
      case DiagnosisStatus.completed:
        setState(() {
          _capturedImageBytes = imageBytes;
          _report = response.report;
          _currentStep = _ScannerStep.result;
        });
        break;
    }
  }

  DiagnosisRequest _buildRequest({Uint8List? imageBytes}) {
    final animal = _selectedAnimal;
    final user = Supabase.instance.client.auth.currentUser;
    final normalizedTemperature =
        _temperatureController.text.trim().replaceAll(',', '.');

    if (animal == null) {
      throw Exception(AppStrings.t('diagnosis_select_animal_first'));
    }

    if (_mainReasonController.text.trim().isEmpty &&
        _symptomsController.text.trim().isEmpty &&
        imageBytes == null) {
      throw Exception(AppStrings.t('diagnosis_write_case_first'));
    }

    if (normalizedTemperature.isNotEmpty &&
        double.tryParse(normalizedTemperature) == null) {
      throw Exception(AppStrings.t('diagnosis_invalid_temperature'));
    }

    final symptomLines = _symptomsController.text
        .split(RegExp(r'[\n,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return DiagnosisRequest(
      animalId: animal.id,
      userId: user?.id ?? animal.userId,
      animalName: animal.name,
      species: 'bovine',
      breed: animal.breed,
      ageInYears: animal.age,
      clinicalQuestion: _mainReasonController.text.trim(),
      reportedSymptoms:
          symptomLines.isNotEmpty ? symptomLines : [animal.symptoms],
      temperature: double.tryParse(normalizedTemperature),
      weight: animal.weight,
      imageBytes: imageBytes,
      imageUrl: animal.imageUrl,
      visualFindings: const [],
    );
  }

  Future<void> _saveDiagnosis() async {
    final animal = _selectedAnimal;
    final report = _report;
    final user = Supabase.instance.client.auth.currentUser;

    if (animal == null || report == null || user == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final normalizedTemperature =
          _temperatureController.text.trim().replaceAll(',', '.');
      final updatedAnimal = AnimalEntity(
        id: animal.id,
        userId: animal.userId,
        name: animal.name,
        breed: animal.breed,
        age: animal.age,
        ageLabel: animal.ageLabel,
        symptoms: _symptomsController.text.trim().isEmpty
            ? animal.symptoms
            : _symptomsController.text.trim(),
        weight: animal.weight,
        temperature: double.tryParse(normalizedTemperature) ?? animal.temperature,
        imageUrl: animal.imageUrl,
        profileImageUrl: animal.profileImageUrl,
        createdAt: animal.createdAt,
        updatedAt: DateTime.now(),
      );

      await ref.read(animalRepositoryProvider).updateAnimal(updatedAnimal);

      final repo = ref.read(medicalRepositoryProvider);
      final record = MedicalRecordModel.fromDiagnosisReport(
        id: const Uuid().v4(),
        animalId: animal.id,
        userId: user.id,
        report: report,
      );
      await repo.addRecord(record);

      if (!mounted) return;
      setState(() {
        _selectedAnimal = updatedAnimal;
      });
      _showMessage(AppStrings.t('diagnosis_saved_message'));
    } catch (error) {
      if (!mounted) return;
      _showMessage('${AppStrings.t('diagnosis_save_error')}: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _resetFlow() {
    setState(() {
      _capturedImageBytes = null;
      _report = null;
      _errorMessage = null;
      _currentStep = _ScannerStep.intake;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _mapCameraError(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return AppStrings.t('scanner_camera_denied');
      case 'CameraNotFound':
        return AppStrings.t('scanner_camera_unavailable');
      default:
        return error.description ?? AppStrings.t('unexpected_error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _currentStep == _ScannerStep.camera
              ? Colors.black
              : const Color(0xFFF8F5FC),
      appBar: AppBar(
        title: Text(AppStrings.t('scanner_title')),
        backgroundColor:
            _currentStep == _ScannerStep.camera
                ? Colors.black
                : Colors.transparent,
        foregroundColor:
            _currentStep == _ScannerStep.camera ? Colors.white : null,
      ),
      body: switch (_currentStep) {
        _ScannerStep.intake => _buildIntakeStep(),
        _ScannerStep.camera => _buildCameraStep(),
        _ScannerStep.result => _buildResultStep(),
      },
      floatingActionButton: _currentStep == _ScannerStep.camera
          ? FloatingActionButton(
              onPressed: _isInitializingCamera || _errorMessage != null
                  ? null
                  : _captureAndAnalyze,
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.camera_alt),
            )
          : null,
    );
  }

  Widget _buildIntakeStep() {
    return FutureBuilder<List<AnimalEntity>>(
      future: _animalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '${AppStrings.t('diagnosis_load_animals_error')}: ${snapshot.error}',
              ),
            ),
          );
        }

        final animals = snapshot.data ?? [];
        if (animals.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pets_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.t('diagnosis_register_animal_first'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddAnimalPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(AppStrings.t('register_animal')),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.t('diagnosis_real_title'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppStrings.t('diagnosis_real_subtitle'),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAnimal?.id,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('diagnosis_animal_label'),
                    ),
                    items: animals
                        .map(
                          (animal) => DropdownMenuItem<String>(
                            value: animal.id,
                            child: Text('${animal.name} • ${animal.breed}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      final selectedAnimal = animals.firstWhere(
                        (item) => item.id == value,
                      );
                      setState(() {
                        _selectedAnimal = selectedAnimal;
                      });
                      _prefillFromAnimal(selectedAnimal);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _mainReasonController,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('diagnosis_main_reason'),
                      hintText: AppStrings.t('diagnosis_main_reason_hint'),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _symptomsController,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('diagnosis_symptoms_label'),
                      hintText: AppStrings.t('diagnosis_symptoms_hint'),
                    ),
                    minLines: 4,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _temperatureController,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('diagnosis_temperature_label'),
                      hintText: AppStrings.t('diagnosis_temperature_hint'),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_capturedImageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.memory(
                        _capturedImageBytes!,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openCamera,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryColor,
                            side: const BorderSide(color: _primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            _capturedImageBytes == null
                                ? AppStrings.t('diagnosis_add_photo')
                                : AppStrings.t('change_photo'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _diagnoseWithoutImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.psychology_alt_outlined),
                          label: Text(AppStrings.t('diagnosis_analyze')),
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCameraStep() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCameraLayer(),
        _buildCameraOverlay(),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: FilledButton.icon(
            onPressed: _isSubmitting
                ? null
                : () {
                    setState(() {
                      _currentStep = _ScannerStep.intake;
                    });
                  },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.55),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.arrow_back),
            label: Text(AppStrings.t('diagnosis_back')),
          ),
        ),
      ],
    );
  }

  Widget _buildResultStep() {
    final report = _report;
    final animal = _selectedAnimal;

    if (report == null || animal == null) {
      return Center(child: Text(AppStrings.t('diagnosis_not_available')));
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.t('diagnosis_animal_prefix')}: ${animal.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  report.diagnosticStatement,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMetricChip(
                      AppStrings.t('diagnosis_severity'),
                      '${report.severityIndex}/100',
                    ),
                    _buildMetricChip(
                      AppStrings.t('diagnosis_urgency'),
                      '${report.urgencyIndex}/100',
                    ),
                    _buildMetricChip(
                      AppStrings.t('diagnosis_contagion'),
                      report.isContagious
                          ? AppStrings.t('yes')
                          : AppStrings.t('no'),
                    ),
                  ],
                ),
                if (_capturedImageBytes != null) ...[
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      _capturedImageBytes!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _buildSection(
                  AppStrings.t('diagnosis_reasoning'),
                  [report.reasoning],
                ),
                _buildSection(
                  AppStrings.t('diagnosis_immediate_actions'),
                  report.immediateActions,
                ),
                _buildSection(
                  AppStrings.t('diagnosis_treatment'),
                  report.treatmentProtocol,
                ),
                if (report.isolationMeasures.isNotEmpty)
                  _buildSection(
                    AppStrings.t('diagnosis_isolation'),
                    report.isolationMeasures,
                  ),
                _buildSection(
                  AppStrings.t('diagnosis_monitoring'),
                  report.monitoringPlan,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveDiagnosis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(AppStrings.t('save')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetFlow,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: const BorderSide(color: _primaryColor),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: Text(AppStrings.t('diagnosis_new_case')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('- $item'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraLayer() {
    final controller = _cameraController;

    if (_isInitializingCamera) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white70,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _initializeCamera,
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh),
                label: Text(AppStrings.t('scanner_retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final previewSize = controller.value.previewSize;

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize?.height ?? 1,
          height: previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _buildCameraOverlay() {
    return IgnorePointer(
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: _targetSize,
              height: _targetSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _targetColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _targetColor.withValues(alpha: 0.28),
                    blurRadius: 18,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                AppStrings.t('diagnosis_camera_optional'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }
}
