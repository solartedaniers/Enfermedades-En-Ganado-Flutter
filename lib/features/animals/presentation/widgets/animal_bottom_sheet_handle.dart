import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_sizes.dart';

class AnimalBottomSheetHandle extends StatelessWidget {
  const AnimalBottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppIconSizes.xLarge,
      height: AppSizes.xSmall,
      margin: const EdgeInsets.symmetric(vertical: AppSizes.medium),
      decoration: BoxDecoration(
        color: context.appColors.inputBorderLight,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
