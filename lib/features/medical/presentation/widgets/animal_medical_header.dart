import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../animals/domain/entities/animal_entity.dart';
import '../../../animals/shared/age_label_formatter.dart';

class AnimalMedicalHeader extends StatelessWidget {
  final AnimalEntity animal;
  final VoidCallback onAvatarTap;

  const AnimalMedicalHeader({
    super.key,
    required this.animal,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appColors.medicalHeaderStart, appColors.medicalHeaderEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: appColors.whiteOverlay,
                  backgroundImage: animal.profileImageUrl != null &&
                          animal.profileImageUrl!.isNotEmpty
                      ? NetworkImage(animal.profileImageUrl!)
                      : null,
                  child: animal.profileImageUrl == null ||
                          animal.profileImageUrl!.isEmpty
                      ? const Icon(Icons.pets, size: 40, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: appColors.chipForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animal.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  animal.breed,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  animal.ageLabel.isNotEmpty
                      ? animal.ageLabel
                      : AgeLabelFormatter.format(animal.age),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (animal.weight != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${animal.weight} ${AppStrings.t("kg")}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
