import 'package:flutter/material.dart';
import '../../../../core/utils/app_strings.dart';
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
            // --- Foto de perfil del animal (Corregida) ---
            animal.profileImageUrl != null && animal.profileImageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      animal.profileImageUrl!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  )
                : GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicalHistoryPage(animal: animal),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Image.asset(
                            AppStrings.t("animal_default_image"), // icon.webp
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            width: double.infinity,
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          const Positioned.fill(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt,
                                    size: 36, color: Colors.white),
                                SizedBox(height: 8),
                                Text(
                                  "Toca para agregar foto de perfil",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 20),

            // --- Info ---
            _infoRow(Icons.pets, AppStrings.t("breed_label"), animal.breed),
            _infoRow(Icons.cake, AppStrings.t("age_label"),
                "${animal.age} ${AppStrings.t("years")}"),
            _infoRow(Icons.sick, AppStrings.t("symptoms_label"), animal.symptoms),
            if (animal.weight != null)
              _infoRow(Icons.monitor_weight, AppStrings.t("weight_label"),
                  "${animal.weight} kg"),
            if (animal.temperature != null)
              _infoRow(Icons.thermostat, AppStrings.t("temperature_label"),
                  "${animal.temperature} °C"),
            const SizedBox(height: 24),

            // --- Botón historial ---
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.medical_services),
                label: Text(AppStrings.t("view_medical_history")),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MedicalHistoryPage(animal: animal),
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
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}