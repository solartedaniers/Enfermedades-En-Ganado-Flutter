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
import '../../../core/network/network_provider.dart';
import '../../../core/services/connectivity_message_presenter.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_strings.dart';
import '../../../geolocation/presentation/providers/geolocation_provider.dart';
import '../../animals/domain/constants/animal_constants.dart';
import '../../animals/domain/entities/animal_entity.dart';
import '../../animals/presentation/pages/add_animal_page.dart';
import '../../animals/presentation/providers/animal_provider.dart';
import '../../medical/data/models/medical_record_model.dart';
import '../../medical/presentation/pages/medical_history_page.dart';
import '../../medical/presentation/providers/medical_provider.dart';
import '../widgets/scanner_camera_view.dart';
import '../widgets/scanner_intake_view.dart';
import '../widgets/scanner_result_view.dart';

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
  static const double _targetSize = 260;
  static const ConnectivityMessagePresenter _connectivityPresenter =
      ConnectivityMessagePresenter();

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
  bool _hasSavedCurrentResult = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animalsFuture = _loadAnimals();
    Future.microtask(
      () => ref
          .read(currentGeolocationContextProvider.notifier)
          .loadCurrentContext(),
    );
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
    final animals = await ref.read(animalsListProvider.future);
    if (_selectedAnimal == null && animals.isNotEmpty) {
      _selectedAnimal = animals.first;
      _prefillFromAnimal(_selectedAnimal!);
    }
    return animals;
  }

  Future<void> _openAddAnimalFlow() async {
    final createdAnimal = await Navigator.of(context).push<AnimalEntity>(
      MaterialPageRoute(builder: (_) => const AddAnimalPage()),
    );

    if (!mounted) {
      return;
    }

    ref.invalidate(animalsListProvider);
    ref.invalidate(rawAnimalsListProvider);

    setState(() {
      _animalsFuture = _loadAnimals();
      if (createdAnimal != null) {
        _selectedAnimal = createdAnimal;
        _prefillFromAnimal(createdAnimal);
      }
    });
  }

  void _prefillFromAnimal(AnimalEntity animal) {
    _temperatureController.text = animal.temperature?.toStringAsFixed(1) ?? '';
    if (_symptomsController.text.trim().isEmpty) {
      _symptomsController.text = animal.symptoms;
    }
  }

  void _selectAnimal(AnimalEntity animal) {
    setState(() {
      _selectedAnimal = animal;
    });
    _prefillFromAnimal(animal);
  }

  Future<void> _initializeCamera() async {
    if (_currentStep != _ScannerStep.camera || _isSubmitting) {
      return;
    }

    setState(() {
      _isInitializingCamera = true;
      _errorMessage = null;
    });

    try {
      final cameras = await availableCameras();
      final rearCamera = cameras.cast<CameraDescription?>().firstWhere(
            (camera) => camera?.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.isNotEmpty ? cameras.first : null,
          );

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
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializingCamera = false;
        _errorMessage = _mapCameraError(error);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

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

  void _backToIntake() {
    setState(() {
      _currentStep = _ScannerStep.intake;
    });
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
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _mapCameraError(error);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

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
      if (!mounted) {
        return;
      }

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

    if (!mounted) {
      return;
    }

    switch (response.status) {
      case DiagnosisStatus.needsConfiguration:
      case DiagnosisStatus.needsInternet:
      case DiagnosisStatus.needsClinicalQuestion:
      case DiagnosisStatus.needsVisualEvidence:
      case DiagnosisStatus.readyToAnalyze:
        if (response.status == DiagnosisStatus.needsInternet) {
          _connectivityPresenter.showOfflineSnackBar(
            context,
            message: response.nextStep.message,
          );
        } else {
          _showMessage(response.nextStep.message);
        }
        break;
      case DiagnosisStatus.completed:
        setState(() {
          _capturedImageBytes = imageBytes;
          _report = response.report;
          _currentStep = _ScannerStep.result;
          _hasSavedCurrentResult = false;
        });
        break;
    }
  }

  DiagnosisRequest _buildRequest({Uint8List? imageBytes}) {
    final animal = _selectedAnimal;
    final currentUser = Supabase.instance.client.auth.currentUser;
    final geolocationContext =
        ref.read(currentGeolocationContextProvider).valueOrNull;
    final normalizedTemperature =
        _temperatureController.text.trim().replaceAll(',', '.');
    final trimmedAnimalSymptoms = animal?.symptoms.trim() ?? '';

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
      userId: currentUser?.id ?? animal.userId,
      animalName: animal.name,
      species: AnimalConstants.cattleSpecies,
      breed: animal.breed,
      ageInYears: animal.age,
      clinicalQuestion: _mainReasonController.text.trim(),
      reportedSymptoms: symptomLines.isNotEmpty
          ? symptomLines
          : trimmedAnimalSymptoms.isNotEmpty
              ? [trimmedAnimalSymptoms]
              : const [],
      temperature: double.tryParse(normalizedTemperature),
      weight: animal.weight,
      imageBytes: imageBytes,
      imageUrl: animal.imageUrl,
      visualFindings: imageBytes == null
          ? const []
          : const ['Captured symptom photo attached for visual analysis.'],
      geolocationContext: geolocationContext,
    );
  }

  Future<void> _saveDiagnosis() async {
    final animal = _selectedAnimal;
    final report = _report;
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (animal == null ||
        report == null ||
        currentUser == null ||
        _isSaving ||
        _hasSavedCurrentResult) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? saveWarningMessage;
      final reportUrl = await ref.read(storageServiceProvider).uploadDiagnosisReportJson(
        diagnosisJson: {
          'source': 'scanner',
          'animal_id': animal.id,
          'animal_name': animal.name,
          'animal_snapshot': {
            'name': animal.name,
            'breed': animal.breed,
            'age_in_months': animal.age,
          },
          'user_id': currentUser.id,
          'has_captured_image': _capturedImageBytes != null,
          'image_url': _capturedImageBytes != null ? animal.imageUrl : null,
          'report': report.toJson(),
          'generated_at': report.generatedAt.toIso8601String(),
        },
        animalName: animal.name,
      );

      try {
        final diagnosisSummary = report.primaryDiagnosis.trim().isNotEmpty
            ? report.primaryDiagnosis.trim()
            : report.diagnosticStatement.trim();

        await Supabase.instance.client.from('animal_diagnostics').insert({
          'id': const Uuid().v4(),
          'animal_id': animal.id,
          'diagnosis_summary': diagnosisSummary,
          'report_url': reportUrl,
          'created_at': report.generatedAt.toIso8601String(),
        });
      } on PostgrestException catch (error) {
        if (error.code == 'PGRST205') {
          saveWarningMessage = AppStrings.t('diagnosis_missing_reports_table');
        } else {
          rethrow;
        }
      }

      final normalizedTemperature =
          _temperatureController.text.trim().replaceAll(',', '.');
      final updatedAnimal = animal.copyWith(
        symptoms: _symptomsController.text.trim().isEmpty
            ? animal.symptoms
            : _symptomsController.text.trim(),
        temperature:
            double.tryParse(normalizedTemperature) ?? animal.temperature,
        updatedAt: DateTime.now(),
      );

      await ref.read(animalRepositoryProvider).updateAnimal(updatedAnimal);

      final medicalRepository = ref.read(medicalRepositoryProvider);
      final record = MedicalRecordModel.fromDiagnosisReport(
        id: const Uuid().v4(),
        animalId: animal.id,
        userId: currentUser.id,
        report: report,
      );
      await medicalRepository.addRecord(record);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedAnimal = updatedAnimal;
        _hasSavedCurrentResult = true;
      });
      refreshAnimals(ref);

      _showMessage(
        saveWarningMessage ?? AppStrings.t('diagnosis_saved_message'),
      );

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MedicalHistoryPage(animal: updatedAnimal),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

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
      _hasSavedCurrentResult = false;
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
    final appColors = context.appColors;
    final theme = Theme.of(context);
    final isCameraStep = _currentStep == _ScannerStep.camera;
    final appBarBackgroundColor =
        isCameraStep ? appColors.authBackgroundDark : theme.colorScheme.surface;
    final appBarForegroundColor =
        isCameraStep ? appColors.onSolid : theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor:
          isCameraStep
              ? appColors.authBackgroundDark
              : appColors.scannerBackground,
      appBar: AppBar(
        title: Text(AppStrings.t('scanner_title')),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
      ),
      body: switch (_currentStep) {
        _ScannerStep.intake => ScannerIntakeView(
            animalsFuture: _animalsFuture,
            selectedAnimal: _selectedAnimal,
            mainReasonController: _mainReasonController,
            symptomsController: _symptomsController,
            temperatureController: _temperatureController,
            capturedImageBytes: _capturedImageBytes,
            isSubmitting: _isSubmitting,
            errorMessage: _errorMessage,
            connectivityState: ref.watch(networkStatusProvider),
            geolocationState: ref.watch(currentGeolocationContextProvider),
            onAnimalSelected: _selectAnimal,
            onAddAnimalRequested: _openAddAnimalFlow,
            onOpenCamera: _openCamera,
            onDiagnoseWithoutImage: _diagnoseWithoutImage,
          ),
        _ScannerStep.camera => ScannerCameraView(
            cameraController: _cameraController,
            isInitializingCamera: _isInitializingCamera,
            isSubmitting: _isSubmitting,
            errorMessage: _errorMessage,
            targetSize: _targetSize,
            onBack: _backToIntake,
            onRetry: _initializeCamera,
          ),
        _ScannerStep.result => ScannerResultView(
            report: _report,
            animal: _selectedAnimal,
            capturedImageBytes: _capturedImageBytes,
            isSaving: _isSaving,
            hasSaved: _hasSavedCurrentResult,
            onSave: _saveDiagnosis,
            onReset: _resetFlow,
          ),
      },
      floatingActionButton: _currentStep == _ScannerStep.camera
          ? FloatingActionButton(
              onPressed: _isInitializingCamera || _errorMessage != null
                  ? null
                  : _captureAndAnalyze,
              backgroundColor: appColors.scannerAccent,
              foregroundColor: appColors.onSolid,
              child: _isSubmitting
                  ? SizedBox(
                      width: AppIconSizes.large,
                      height: AppIconSizes.large,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          appColors.onSolid,
                        ),
                      ),
                    )
                  : const Icon(Icons.camera_alt),
            )
          : null,
    );
  }
}
