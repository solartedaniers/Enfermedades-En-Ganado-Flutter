import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ai/models/diagnosis_request.dart';
import '../../../core/ai/models/diagnosis_response.dart';
import '../../../core/ai/providers/ai_diagnosis_provider.dart';
import '../../../core/utils/app_strings.dart';
import '../../animals/presentation/pages/animals_page.dart';

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
  static const Color _scannerActionColor = Color(0xFFBF22DF);
  static const Color _targetColor = Color(0xFF34C759);
  static const double _targetSize = 260;

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _visualNotesController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();

  CameraController? _cameraController;
  DiagnosisReport? _report;
  Uint8List? _capturedImageBytes;
  _ScannerStep _step = _ScannerStep.intake;
  bool _isInitializing = false;
  bool _isAnalyzing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;

    if (_step != _ScannerStep.camera ||
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
    _questionController.dispose();
    _symptomsController.dispose();
    _visualNotesController.dispose();
    _temperatureController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (_isAnalyzing || _step != _ScannerStep.camera) return;

    setState(() {
      _isInitializing = true;
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
        _isInitializing = false;
      });
    } on CameraException catch (error) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _errorMessage = _mapCameraError(error);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _errorMessage = AppStrings.t('unexpected_error');
      });
    }
  }

  Future<void> _startDiagnosisFlow() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(livestockDiagnosisServiceProvider);
      final request = _buildRequest();
      final preparation = await service.prepare(request);

      if (!mounted) return;

      switch (preparation.status) {
        case DiagnosisStatus.needsInternet:
          await _showOfflineDialog(preparation.nextStep);
          break;
        case DiagnosisStatus.needsClinicalQuestion:
          _showMessage(preparation.nextStep.message);
          break;
        case DiagnosisStatus.needsVisualEvidence:
          setState(() {
            _step = _ScannerStep.camera;
          });
          await _initializeCamera();
          break;
        case DiagnosisStatus.readyToAnalyze:
          await _runDiagnosis(request);
          break;
        case DiagnosisStatus.completed:
          break;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _captureAndAnalyze() async {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized || _isAnalyzing) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final picture = await controller.takePicture();
      final bytes = await File(picture.path).readAsBytes();
      final request = _buildRequest(imageBytes: bytes);

      await _runDiagnosis(request);
    } on CameraException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _mapCameraError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _runDiagnosis(DiagnosisRequest request) async {
    final service = ref.read(livestockDiagnosisServiceProvider);
    final response = await service.analyze(request);

    if (!mounted) return;

    if (response.isCompleted) {
      setState(() {
        _capturedImageBytes = request.imageBytes;
        _report = response.report;
        _step = _ScannerStep.result;
      });
      return;
    }

    _showMessage(response.nextStep.message);
  }

  DiagnosisRequest _buildRequest({Uint8List? imageBytes}) {
    final user = Supabase.instance.client.auth.currentUser;
    final symptoms = _symptomsController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final visualNotes = _visualNotesController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return DiagnosisRequest(
      animalId: 'scanner_session',
      userId: user?.id ?? 'guest',
      animalName: 'Ganado en evaluación',
      clinicalQuestion: _questionController.text.trim(),
      reportedSymptoms: symptoms,
      visualFindings: visualNotes,
      temperature: double.tryParse(
        _temperatureController.text.trim().replaceAll(',', '.'),
      ),
      imageBytes: imageBytes,
    );
  }

  Future<void> _showOfflineDialog(DiagnosisNextStep nextStep) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(nextStep.title),
          content: Text(nextStep.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AnimalsPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _scannerActionColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ir a historial'),
            ),
          ],
        );
      },
    );
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
          _step == _ScannerStep.camera ? Colors.black : const Color(0xFFF8F5FC),
      appBar: AppBar(
        title: Text(AppStrings.t('scanner_title')),
        backgroundColor:
            _step == _ScannerStep.camera ? Colors.black : Colors.transparent,
        foregroundColor: _step == _ScannerStep.camera ? Colors.white : null,
      ),
      body: switch (_step) {
        _ScannerStep.intake => _buildIntakeStep(),
        _ScannerStep.camera => _buildCameraStep(),
        _ScannerStep.result => _buildResultStep(),
      },
      floatingActionButton: _step == _ScannerStep.camera
          ? FloatingActionButton(
              onPressed: _isInitializing || _errorMessage != null
                  ? null
                  : _captureAndAnalyze,
              tooltip: AppStrings.t('scanner_capture'),
              backgroundColor: _scannerActionColor,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: _isAnalyzing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.document_scanner_outlined),
            )
          : null,
    );
  }

  Widget _buildIntakeStep() {
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
                  color: _scannerActionColor.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Primero cuéntame qué le pasa al animal',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'La cámara ya no se abre de una. Primero escribes el caso y el motor decide si necesita foto o si puede diagnosticar con síntomas.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _questionController,
                  decoration: const InputDecoration(
                    labelText: '¿Qué le preocupa del animal?',
                    hintText: 'Ej: tiene la ubre inflamada y está decaído',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _symptomsController,
                  decoration: const InputDecoration(
                    labelText: 'Síntomas observados',
                    hintText: 'Sepáralos por comas',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _temperatureController,
                  decoration: const InputDecoration(
                    labelText: 'Temperatura (opcional)',
                    hintText: 'Ej: 39.8',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _visualNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Hallazgos visibles si ya los viste',
                    hintText: 'Ej: lesiones en piel, babeo, ubre caliente',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _startDiagnosisFlow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _scannerActionColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.psychology_alt_outlined),
                    label: Text(
                      _isAnalyzing ? 'Revisando evidencia...' : 'Continuar diagnóstico',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraStep() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCameraLayer(),
        _buildOverlay(context),
        if (_errorMessage == null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: FilledButton.icon(
              onPressed: _isAnalyzing
                  ? null
                  : () {
                      setState(() {
                        _step = _ScannerStep.intake;
                      });
                    },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.55),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver a los datos clínicos'),
            ),
          ),
      ],
    );
  }

  Widget _buildResultStep() {
    final report = _report;

    if (report == null) {
      return const Center(child: Text('No hay diagnóstico disponible.'));
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
                  color: _scannerActionColor.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      'Severidad',
                      '${report.severityIndex}/100',
                    ),
                    _buildMetricChip('Urgencia', '${report.urgencyIndex}/100'),
                    _buildMetricChip(
                      'Contagio',
                      report.isContagious ? 'Sí' : 'No',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_capturedImageBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      _capturedImageBytes!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _buildSection('Razonamiento', [report.reasoning]),
                _buildSection('Acciones inmediatas', report.immediateActions),
                _buildSection('Tratamiento sugerido', report.treatmentProtocol),
                if (report.isolationMeasures.isNotEmpty)
                  _buildSection('Aislamiento', report.isolationMeasures),
                _buildSection('Monitoreo', report.monitoringPlan),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _report = null;
                        _capturedImageBytes = null;
                        _step = _ScannerStep.intake;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _scannerActionColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Nuevo diagnóstico'),
                  ),
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
        color: _scannerActionColor.withValues(alpha: 0.08),
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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

    if (_isInitializing) {
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
                  backgroundColor: _scannerActionColor,
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

  Widget _buildOverlay(BuildContext context) {
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
              child: Stack(
                children: [
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'La IA pidió foto para confirmar el diagnóstico. Centra el síntoma dentro del recuadro.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
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

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _targetColor, width: 3),
        ),
      ),
    );
  }
}
