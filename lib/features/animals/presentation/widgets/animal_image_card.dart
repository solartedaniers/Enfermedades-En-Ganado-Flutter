import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
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
            width: 1.5,
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

    return Container(
      color: appColors.cameraOverlay,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(overlayIcon, size: 44, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            overlayLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (overlaySubtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              overlaySubtitle!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
