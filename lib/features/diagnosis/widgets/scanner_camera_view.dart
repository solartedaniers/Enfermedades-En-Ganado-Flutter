import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_strings.dart';

class ScannerCameraView extends StatelessWidget {
  final CameraController? cameraController;
  final bool isInitializingCamera;
  final bool isSubmitting;
  final String? errorMessage;
  final double targetSize;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const ScannerCameraView({
    super.key,
    required this.cameraController,
    required this.isInitializingCamera,
    required this.isSubmitting,
    required this.errorMessage,
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
}

class _ScannerCameraOverlay extends StatelessWidget {
  final double targetSize;

  const _ScannerCameraOverlay({required this.targetSize});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Container(
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
            const SizedBox(height: AppSizes.xxxLarge),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxLarge),
              child: Text(
                AppStrings.t('diagnosis_camera_optional'),
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle(Theme.of(context)).copyWith(
                  color: context.appColors.onSolid,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(height: AppSizes.formBottomSpacing + AppSizes.xLarge),
          ],
        ),
      ),
    );
  }
}
