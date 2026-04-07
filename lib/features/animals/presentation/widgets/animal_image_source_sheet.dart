import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import 'animal_bottom_sheet_handle.dart';

class AnimalImageSourceSheet extends StatelessWidget {
  final ValueChanged<ImageSource> onSourceSelected;

  const AnimalImageSourceSheet({
    super.key,
    required this.onSourceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.cardRadius),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnimalBottomSheetHandle(),
            ListTile(
              leading: Icon(Icons.camera_alt, color: appColors.chipForeground),
              title: Text(AppStrings.t('take_photo')),
              onTap: () => onSourceSelected(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: appColors.chipForeground),
              title: Text(AppStrings.t('choose_gallery')),
              onTap: () => onSourceSelected(ImageSource.gallery),
            ),
            const SizedBox(height: AppSizes.small),
          ],
        ),
      ),
    );
  }
}
