import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/app_strings.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  static const Color _scannerActionColor = Color(0xFFBF22DF);
  static const Color _targetColor = Color(0xFF34C759);
  static const double _targetSize = 260;

  CameraController? _cameraController;
  bool _isInitializing = true;
  bool _isAnalyzing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    // Liberamos la cámara temporalmente cuando la app pasa a segundo plano.
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _cameraController = null;
      return;
    }

    // Al regresar a la app, intentamos recuperar la cámara.
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
    if (_isAnalyzing) return;

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
        imageFormatGroup: ImageFormatGroup.yuv420,
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

  Future<void> _captureAndAnalyze() async {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized || _isAnalyzing) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final frameCompleter = Completer<CameraImage>();

      await controller.startImageStream((CameraImage image) {
        if (!frameCompleter.isCompleted) {
          frameCompleter.complete(image);
        }
      });

      final image = await frameCompleter.future.timeout(
        const Duration(seconds: 3),
      );

      await _processImage(image);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('scanner_analyzing')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _errorMessage = AppStrings.t('load_error');
      });
    } on CameraException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _mapCameraError(error);
      });
    } finally {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  // Este método queda como punto de integración para el modelo TFLite.
  Future<void> _processImage(CameraImage image) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
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
    return Theme(
      data: Theme.of(context).copyWith(useMaterial3: true),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildCameraLayer(),
            _buildOverlay(context),
            _buildTopBar(context),
          ],
        ),
        floatingActionButton: FloatingActionButton(
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
        ),
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
                AppStrings.t('scanner_instruction'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.t('scanner_title'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isAnalyzing
                          ? AppStrings.t('scanner_analyzing')
                          : AppStrings.t('scanner_ready'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
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
