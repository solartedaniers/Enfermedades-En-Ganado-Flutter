import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_strings.dart';
import '../../../core/ai/models/diagnosis_response.dart';
import '../../animals/domain/entities/animal_entity.dart';

class ScannerResultView extends StatelessWidget {
  final DiagnosisReport? report;
  final AnimalEntity? animal;
  final Uint8List? capturedImageBytes;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onReset;

  const ScannerResultView({
    super.key,
    required this.report,
    required this.animal,
    required this.capturedImageBytes,
    required this.isSaving,
    required this.onSave,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final currentReport = report;
    final currentAnimal = animal;

    if (currentReport == null || currentAnimal == null) {
      return Center(child: Text(AppStrings.t('diagnosis_not_available')));
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: context.appColors.scannerAccent.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.t('diagnosis_animal_prefix')}: ${currentAnimal.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentReport.diagnosticStatement,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ScannerMetricChip(
                      title: AppStrings.t('diagnosis_severity'),
                      value: '${currentReport.severityIndex}/100',
                    ),
                    _ScannerMetricChip(
                      title: AppStrings.t('diagnosis_urgency'),
                      value: '${currentReport.urgencyIndex}/100',
                    ),
                    _ScannerMetricChip(
                      title: AppStrings.t('diagnosis_contagion'),
                      value: currentReport.isContagious
                          ? AppStrings.t('yes')
                          : AppStrings.t('no'),
                    ),
                  ],
                ),
                if (capturedImageBytes != null) ...[
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      capturedImageBytes!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _ScannerSection(
                  title: AppStrings.t('diagnosis_reasoning'),
                  items: [currentReport.reasoning],
                ),
                _ScannerSection(
                  title: AppStrings.t('diagnosis_immediate_actions'),
                  items: currentReport.immediateActions,
                ),
                _ScannerSection(
                  title: AppStrings.t('diagnosis_treatment'),
                  items: currentReport.treatmentProtocol,
                ),
                if (currentReport.isolationMeasures.isNotEmpty)
                  _ScannerSection(
                    title: AppStrings.t('diagnosis_isolation'),
                    items: currentReport.isolationMeasures,
                  ),
                _ScannerSection(
                  title: AppStrings.t('diagnosis_monitoring'),
                  items: currentReport.monitoringPlan,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appColors.scannerAccent,
                          foregroundColor: context.appColors.onSolid,
                        ),
                        icon: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(AppStrings.t('save')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReset,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.appColors.scannerAccent,
                          side: BorderSide(
                            color: context.appColors.scannerAccent,
                          ),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: Text(AppStrings.t('diagnosis_new_case')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerMetricChip extends StatelessWidget {
  final String title;
  final String value;

  const _ScannerMetricChip({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.appColors.scannerAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.appColors.subduedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _ScannerSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('- $item'),
            ),
          ),
        ],
      ),
    );
  }
}
