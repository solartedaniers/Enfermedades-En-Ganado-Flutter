import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AnimalBottomSheetHandle extends StatelessWidget {
  const AnimalBottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: context.appColors.inputBorderLight,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
