import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/ai/models/livestock_detection.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_strings.dart';

class ScannerCameraView extends StatelessWidget {
  final CameraController? cameraController;
  final bool isInitializingCamera;
  final bool isSubmitting;
  final String? errorMessage;
  final LivestockDetection? livestockDetection;
  final double targetSize;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const ScannerCameraView({
    super.key,
    required this.cameraController,
    required this.isInitializingCamera,
    required this.isSubmitting,
    required this.errorMessage,
    required this.livestockDetection,
    required this.targetSize,
    required this.onBack,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCameraLayer(context),
        _ScannerCameraOverlay(targetSize: targetSize),
        if (livestockDetection != null)
          _LivestockDetectionOverlay(
            detection: livestockDetection!,
            previewSize: _previewDisplaySize,
          ),
        Positioned(
          left: AppSizes.large,
          right: AppSizes.large,
          bottom: AppSizes.bottomActionInset,
          child: FilledButton.icon(
            onPressed: isSubmitting ? null : onBack,
            style: FilledButton.styleFrom(
              backgroundColor: context.appColors.cameraOverlay,
              foregroundColor: context.appColors.onSolid,
            ),
            icon: const Icon(Icons.arrow_back),
            label: Text(AppStrings.t('diagnosis_back')),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraLayer(BuildContext context) {
    final controller = cameraController;

    if (isInitializingCamera) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                color: context.appColors.onSolid,
                size: AppIconSizes.xxLarge,
              ),
              const SizedBox(height: AppSizes.large),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle(
                  Theme.of(context),
                ).copyWith(color: context.appColors.onSolid),
              ),
              const SizedBox(height: AppSizes.xLarge),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: context.appColors.scannerAccent,
                  foregroundColor: context.appColors.onSolid,
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

  Size? get _previewDisplaySize {
    final previewSize = cameraController?.value.previewSize;
    if (previewSize == null) {
      return null;
    }

    return Size(previewSize.height, previewSize.width);
  }
}

class _LivestockDetectionOverlay extends StatelessWidget {
  final LivestockDetection detection;
  final Size? previewSize;

  const _LivestockDetectionOverlay({
    required this.detection,
    required this.previewSize,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final box = detection.boundingBox;
          final previewRect = _resolvePreviewRect(constraints);
          final left = previewRect.left + box.left * previewRect.width;
          final top = previewRect.top + box.top * previewRect.height;
          final width = box.width * previewRect.width;
          final height = box.height * previewRect.height;
          final labelTop = (top - 36).clamp(12.0, constraints.maxHeight - 48);

          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                width: width,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.medium),
                    border: Border.all(
                      color: context.appColors.success,
                      width: AppSizes.thickStroke,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: left.clamp(12.0, constraints.maxWidth - 120),
                top: labelTop,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.medium,
                    vertical: AppSizes.small,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.success,
                    borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
                  ),
                  child: Text(
                    '${detection.species} ${(detection.confidence * 100).toStringAsFixed(1)}%',
                    style: AppTextStyles.bodyStrong(
                      Theme.of(context),
                      context.appColors.onSolid,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Rect _resolvePreviewRect(BoxConstraints constraints) {
    final size = previewSize;
    if (size == null || size.width <= 0 || size.height <= 0) {
      return Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight);
    }

    final scale = math.max(
      constraints.maxWidth / size.width,
      constraints.maxHeight / size.height,
    );
    final displayedWidth = size.width * scale;
    final displayedHeight = size.height * scale;
    final left = (constraints.maxWidth - displayedWidth) / 2;
    final top = (constraints.maxHeight - displayedHeight) / 2;

    return Rect.fromLTWH(left, top, displayedWidth, displayedHeight);
  }
}

class _ScannerCameraOverlay extends StatelessWidget {
  final double targetSize;

  const _ScannerCameraOverlay({required this.targetSize});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Container(
                width: targetSize,
                height: targetSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.xxxLarge),
                  border: Border.all(
                    color: context.appColors.scannerTarget,
                    width: AppSizes.thickStroke,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.scannerTarget.withValues(alpha: 0.28),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: AppSizes.large,
              left: AppSizes.large,
              right: AppSizes.large,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.medium),
                child: Text(
                  AppStrings.t('diagnosis_camera_required'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(
                    Theme.of(context),
                    context.appColors.onSolid.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
