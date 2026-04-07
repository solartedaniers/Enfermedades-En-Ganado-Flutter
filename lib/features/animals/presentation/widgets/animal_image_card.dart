import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_strings.dart';

class AnimalImageCard extends StatelessWidget {
  final File? selectedImage;
  final String? networkImageUrl;
  final double height;
  final BorderRadius borderRadius;
  final VoidCallback onTap;
  final String overlayLabel;
  final String? overlaySubtitle;
  final IconData overlayIcon;
  final bool showOverlay;

  const AnimalImageCard({
    super.key,
    required this.selectedImage,
    required this.networkImageUrl,
    required this.height,
    required this.borderRadius,
    required this.onTap,
    required this.overlayLabel,
    required this.overlayIcon,
    this.overlaySubtitle,
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: appColors.inputBorderLight,
            width: AppSizes.thinStroke,
          ),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImageContent(),
              if (showOverlay) _buildOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    if (selectedImage != null) {
      return Image.file(selectedImage!, fit: BoxFit.cover);
    }

    if (networkImageUrl != null && networkImageUrl!.isNotEmpty) {
      return Image.network(
        networkImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
      );
    }

    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      AppStrings.t('animal_default_image'),
      fit: BoxFit.cover,
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final appColors = context.appColors;
    final overlaySubtitleColor = appColors.onSolid.withValues(alpha: 0.8);

    return Container(
      color: appColors.cameraOverlay,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(overlayIcon, size: AppIconSizes.xLarge + 4, color: appColors.onSolid),
          const SizedBox(height: AppSizes.small),
          Text(
            overlayLabel,
            style: AppTextStyles.bodyStrong(Theme.of(context), appColors.onSolid),
          ),
          if (overlaySubtitle != null) ...[
            const SizedBox(height: AppSizes.xSmall),
            Text(
              overlaySubtitle!,
              style: AppTextStyles.bodyMuted(Theme.of(context), overlaySubtitleColor),
            ),
          ],
        ],
      ),
    );
  }
}
