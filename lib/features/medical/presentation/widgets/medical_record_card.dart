import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/app_date_formatter.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../domain/entities/medical_record_entity.dart';

class MedicalRecordCard extends StatelessWidget {
  final MedicalRecordEntity record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicalRecordCard({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: appColors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  AppDateFormatter.shortDate(record.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: appColors.mutedForeground,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.edit, size: 18, color: appColors.chipForeground),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 18, color: appColors.danger),
                  onPressed: onDelete,
                ),
              ],
            ),
            if (record.imageUrl != null && record.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  record.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${AppStrings.t("diagnosis_label")}:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(record.diagnosis ?? AppStrings.t('no_diagnosis')),
            const SizedBox(height: 8),
            Text(
              '${AppStrings.t("ai_result")}:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(record.aiResult ?? AppStrings.t('no_ai_result')),
          ],
        ),
      ),
    );
  }
}
