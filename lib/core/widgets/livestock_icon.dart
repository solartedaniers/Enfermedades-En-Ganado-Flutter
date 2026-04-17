import 'package:flutter/material.dart';

import '../../features/animals/domain/constants/animal_constants.dart';

class LivestockIcon extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry padding;

  const LivestockIcon({
    super.key,
    this.size = 24,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 3),
        child: Image.asset(
          AnimalConstants.livestockAssetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
