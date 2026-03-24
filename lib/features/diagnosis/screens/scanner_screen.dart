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

class _SelectableOption {
  final String label;
  final String value;

  const _SelectableOption({
    required this.label,
    required this.value,
  });
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
  static const List<_SelectableOption> _concernOptions = [
    _SelectableOption(
      label: 'Problema en ubre o leche',
      value: 'mastitis',
    ),
    _SelectableOption(
      label: 'Problema respiratorio',
      value: 'neumonia bovina',
    ),
    _SelectableOption(
      label: 'Lesiones en piel',
      value: 'dermatofitosis',
    ),
    _SelectableOption(
      label: 'Problema digestivo',
      value: 'gastroenteritis',
    ),
    _SelectableOption(
      label: 'Lesiones en boca o pezuñas',
      value: 'fiebre aftosa',
    ),
  ];
  static const List<_SelectableOption> _symptomOptions = [
    _SelectableOption(label: 'Ubre inflamada', value: 'ubre inflamada'),
    _SelectableOption(label: 'Ubre caliente', value: 'ubre caliente'),
    _SelectableOption(label: 'Leche grumosa', value: 'leche grumosa'),
    _SelectableOption(label: 'Tos', value: 'tos'),
    _SelectableOption(
      label: 'Dificultad respiratoria',
      value: 'dificultad respiratoria',
    ),
    _SelectableOption(label: 'Secreción nasal', value: 'secrecion nasal'),
    _SelectableOption(label: 'Diarrea', value: 'diarrea'),
    _SelectableOption(label: 'Deshidratación', value: 'deshidratacion'),
    _SelectableOption(label: 'Debilidad', value: 'debilidad'),
    _SelectableOption(label: 'Cojera', value: 'cojera'),
    _SelectableOption(label: 'Babeo', value: 'babeo'),
    _SelectableOption(label: 'Pérdida de pelo', value: 'caida de pelo'),
  ];
  static const List<_SelectableOption> _visualFindingOptions = [
    _SelectableOption(label: 'Lesiones en piel', value: 'lesiones en piel'),
    _SelectableOption(label: 'Manchas circulares', value: 'manchas circulares'),
    _SelectableOption(label: 'Costras', value: 'costras'),
    _SelectableOption(label: 'Llagas en boca', value: 'llagas en boca'),
    _SelectableOption(label: 'Lesiones en pezuñas', value: 'lesiones pezuñas'),
    _SelectableOption(label: 'Ubre endurecida', value: 'dolor en ubre'),
  ];
  static const List<_SelectableOption> _temperatureOptions = [
    _SelectableOption(label: 'Sin medir', value: ''),
    _SelectableOption(label: 'Normal (38.5 °C)', value: '38.5'),
    _SelectableOption(label: 'Leve fiebre (39.3 °C)', value: '39.3'),
    _SelectableOption(label: 'Fiebre (39.8 °C)', value: '39.8'),
    _SelectableOption(label: 'Alta fiebre (40.5 °C)', value: '40.5'),
  ];

  CameraController? _cameraController;
  DiagnosisReport? _report;
  Uint8List? _capturedImageBytes;
  _ScannerStep _step = _ScannerStep.intake;
  String? _selectedConcern;
  String _selectedTemperature = '';
  final Set<String> _selectedSymptoms = {};
  final Set<String> _selectedVisualFindings = {};
  DiagnosisNextStep? _pendingNextStep;
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
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _pendingNextStep = null;
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
          setState(() {
            _pendingNextStep = preparation.nextStep;
          });
          break;
        case DiagnosisStatus.needsVisualEvidence:
          setState(() {
            _pendingNextStep = preparation.nextStep;
          });
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
    String? concernLabel;
    for (final option in _concernOptions) {
      if (option.value == _selectedConcern) {
        concernLabel = option.label;
        break;
      }
    }

    return DiagnosisRequest(
      animalId: 'scanner_session',
      userId: user?.id ?? 'guest',
      animalName: 'Ganado en evaluación',
      clinicalQuestion: concernLabel ?? '',
      reportedSymptoms: _selectedSymptoms.toList(),
      visualFindings: _selectedVisualFindings.toList(),
      temperature: double.tryParse(_selectedTemperature),
      imageBytes: imageBytes,
    );
  }

  Future<void> _openCameraStep() async {
    setState(() {
      _step = _ScannerStep.camera;
      _pendingNextStep = null;
    });
    await _initializeCamera();
  }

  void _toggleValue(Set<String> source, String value) {
    setState(() {
      if (source.contains(value)) {
        source.remove(value);
      } else {
        source.add(value);
      }
    });
  }

  void _resetDiagnosis() {
    setState(() {
      _report = null;
      _capturedImageBytes = null;
      _selectedConcern = null;
      _selectedTemperature = '';
      _selectedSymptoms.clear();
      _selectedVisualFindings.clear();
      _pendingNextStep = null;
      _step = _ScannerStep.intake;
    });
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
                  'Diagnóstico guiado del animal',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ahora el formulario es cerrado para evitar diagnósticos por texto libre. Selecciona el problema principal, los síntomas y, si quieres, agrega foto con cámara.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _selectedConcern,
                  decoration: const InputDecoration(
                    labelText: 'Motivo principal del diagnóstico',
                  ),
                  items: _concernOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.value,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedConcern = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildChoiceGroup(
                  title: 'Síntomas observados',
                  options: _symptomOptions,
                  selectedValues: _selectedSymptoms,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTemperature,
                  decoration: const InputDecoration(
                    labelText: 'Temperatura',
                  ),
                  items: _temperatureOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.value,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTemperature = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildChoiceGroup(
                  title: 'Hallazgos visibles',
                  options: _visualFindingOptions,
                  selectedValues: _selectedVisualFindings,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F0FC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _scannerActionColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        color: _scannerActionColor,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'La cámara es opcional. Úsala si el síntoma tiene algo visible como lesiones, piel, boca, pezuñas o ubre.',
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _openCameraStep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _scannerActionColor,
                          side: const BorderSide(color: _scannerActionColor),
                        ),
                        child: const Text('Abrir cámara'),
                      ),
                    ],
                  ),
                ),
                if (_pendingNextStep != null) ...[
                  const SizedBox(height: 16),
                  _buildDecisionCard(_pendingNextStep!),
                ],
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
                      _isAnalyzing
                          ? 'Analizando encuesta...'
                          : 'Diagnosticar con la IA',
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
              label: const Text('Volver al formulario'),
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
                      _resetDiagnosis();
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

  Widget _buildChoiceGroup({
    required String title,
    required List<_SelectableOption> options,
    required Set<String> selectedValues,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options
              .map(
                (option) => FilterChip(
                  label: Text(option.label),
                  selected: selectedValues.contains(option.value),
                  onSelected: (_) => _toggleValue(selectedValues, option.value),
                  selectedColor: _scannerActionColor.withValues(alpha: 0.18),
                  checkmarkColor: _scannerActionColor,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDecisionCard(DiagnosisNextStep nextStep) {
    final needsCamera = nextStep.status == DiagnosisStatus.needsVisualEvidence;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: needsCamera
              ? _targetColor
              : _scannerActionColor.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nextStep.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(nextStep.message),
          if (needsCamera) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _openCameraStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _scannerActionColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Continuar con cámara'),
            ),
          ],
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
