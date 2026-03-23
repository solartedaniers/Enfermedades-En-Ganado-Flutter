import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_strings.dart';
import '../providers/medical_provider.dart';

class MedicalHistoryPage extends ConsumerWidget {
  final String animalId;
  final String animalName;

  const MedicalHistoryPage({
    super.key,
    required this.animalId,
    required this.animalName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(medicalRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("${AppStrings.t("medical_history")} - $animalName"),
      ),
      body: FutureBuilder(
        future: repo.getRecords(animalId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("${AppStrings.t("load_error")}: ${snapshot.error}"),
            );
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.medical_services_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.t("no_records"),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "${record.createdAt.day}/${record.createdAt.month}/${record.createdAt.year}",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${AppStrings.t("diagnosis_label")}:",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(record.diagnosis ?? AppStrings.t("no_diagnosis")),
                      const SizedBox(height: 8),
                      Text(
                        "${AppStrings.t("ai_result")}:",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(record.aiResult ?? AppStrings.t("no_ai_result")),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}