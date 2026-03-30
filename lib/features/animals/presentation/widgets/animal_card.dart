import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/animal_entity.dart';
import '../../shared/age_label_formatter.dart';

class AnimalCard extends StatelessWidget {
  final AnimalEntity animalData;
  final VoidCallback onTap;

  const AnimalCard({
    super.key,
    required this.animalData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appColors = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? appColors.cardDark : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Imagen de perfil ────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(20)),
              child: animalData.profileImageUrl != null &&
                      animalData.profileImageUrl!.isNotEmpty
                  ? Image.network(
                      animalData.profileImageUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholder(),
                    )
                  : _placeholder(),
            ),

            // ── Info ────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      animalData.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : appColors.subduedForeground,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      animalData.breed,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: appColors.mutedForeground,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _chip(
                          context,
                          Icons.cake,
                          animalData.ageLabel.isNotEmpty
                              ? animalData.ageLabel
                              : AgeLabelFormatter.format(animalData.age),
                        ),
                        if (animalData.weight != null)
                          _chip(
                            context,
                            Icons.monitor_weight,
                            '${animalData.weight} ${AppStrings.t("kg")}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Flecha ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: appColors.inputBorderLight,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05);
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    final appColors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: appColors.selectionBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: appColors.chipForeground),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: appColors.chipForeground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Image.asset(
      AppStrings.t('animal_default_image'),
      width: 100,
      height: 100,
      fit: BoxFit.cover,
    );
  }
}
