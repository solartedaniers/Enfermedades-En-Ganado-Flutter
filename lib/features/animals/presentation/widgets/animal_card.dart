import 'package:flutter/material.dart';
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
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // --- Imagen ---
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: animal.imageUrl != null && animal.imageUrl!.isNotEmpty
                  ? Image.network(
                      animal.imageUrl!,
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      animal.breed,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.cake, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "${animal.age} años",
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (animal.weight != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.monitor_weight,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "${animal.weight} kg",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[200],
      child: const Icon(Icons.pets, size: 40, color: Colors.grey),
    );
  }
}