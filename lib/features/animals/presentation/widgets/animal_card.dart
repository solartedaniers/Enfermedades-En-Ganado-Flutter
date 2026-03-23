import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/animal_entity.dart';

class AnimalCard extends StatelessWidget {
  final AnimalEntity animal;
  final VoidCallback onTap;

  const AnimalCard({
    super.key,
    required this.animal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
          children: [
            // --- Imagen de perfil del animal ---
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20)),
              child: animal.profileImageUrl != null &&
                      animal.profileImageUrl!.isNotEmpty
                  ? Image.network(
                      animal.profileImageUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => _placeholder(),
                    )
                  : _placeholder(),
            ),

            // --- Info ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      animal.breed,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _chip(Icons.cake,
                            "${animal.age} ${AppStrings.t("years")}"),
                        if (animal.weight != null) ...[
                          const SizedBox(width: 8),
                          _chip(Icons.monitor_weight,
                              "${animal.weight} kg"),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05);
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF2E7D32))),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Image.asset(
      AppStrings.t("animal_default_image"),
      width: 100,
      height: 100,
      fit: BoxFit.cover,
    );
  }
}