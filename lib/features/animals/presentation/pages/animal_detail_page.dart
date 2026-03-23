import 'package:flutter/material.dart';
import '../../domain/entities/animal_entity.dart';
import '../../../medical/presentation/pages/medical_history_page.dart';

class AnimalDetailPage extends StatelessWidget {
  final AnimalEntity animal;

  const AnimalDetailPage({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(animal.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Imagen ---
            if (animal.imageUrl != null && animal.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  animal.imageUrl!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.pets, size: 80, color: Colors.grey),
              ),
            const SizedBox(height: 20),

            // --- Info ---
            _infoRow(Icons.pets, "Raza", animal.breed),
            _infoRow(Icons.cake, "Edad", "${animal.age} años"),
            _infoRow(Icons.sick, "Síntomas", animal.symptoms),
            if (animal.weight != null)
              _infoRow(Icons.monitor_weight, "Peso",
                  "${animal.weight} kg"),
            if (animal.temperature != null)
              _infoRow(Icons.thermostat, "Temperatura",
                  "${animal.temperature} °C"),
            const SizedBox(height: 24),

            // --- Botón historial ---
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.medical_services),
                label: const Text("Ver historial clínico"),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MedicalHistoryPage(
                      animalId: animal.id,
                      animalName: animal.name,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Text("$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}