import 'dart:math' as math;

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
        _ScanningAnimationOverlay(),
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
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          const Color(0xFF00FF88).withValues(alpha: 0.12),
          BlendMode.colorDodge,
        ),
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize?.height ?? 1,
            height: previewSize?.width ?? 1,
            child: CameraPreview(controller),
          ),
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

class _ScanningAnimationOverlay extends StatefulWidget {
  const _ScanningAnimationOverlay();

  @override
  State<_ScanningAnimationOverlay> createState() =>
      _ScanningAnimationOverlayState();
}

class _ScanningAnimationOverlayState extends State<_ScanningAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _ScanningLinePainter(
              progress: _animation.value,
              color: context.appColors.scannerAccent,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ScanningLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanningLinePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * progress;

    // Línea horizontal principal
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2.5;

    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      paint,
    );

    // Efecto de brillo/glow alrededor de la línea
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 15
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      glowPaint,
    );

    // Puntos de reflexión
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += size.width / 8) {
      canvas.drawCircle(Offset(x, centerY), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ScanningLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
