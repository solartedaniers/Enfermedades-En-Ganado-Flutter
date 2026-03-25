import 'dart:convert';

import '../../utils/app_strings.dart';

enum DiagnosisStatus {
  needsConfiguration,
  needsInternet,
  needsClinicalQuestion,
  needsVisualEvidence,
  readyToAnalyze,
  completed,
}

class DiagnosisNextStep {
  final DiagnosisStatus status;
  final String title;
  final String message;
  final bool canContinueOffline;
  final List<String> suggestedRoutes;

  const DiagnosisNextStep({
    required this.status,
    required this.title,
    required this.message,
    this.canContinueOffline = false,
    this.suggestedRoutes = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'title': title,
      'message': message,
      'can_continue_offline': canContinueOffline,
      'suggested_routes': suggestedRoutes,
    };
  }
}

class DiagnosisFinding {
  final String label;
  final String source;
  final double confidence;
  final String interpretation;

  const DiagnosisFinding({
    required this.label,
    required this.source,
    required this.confidence,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'source': source,
      'confidence': confidence,
      'interpretation': interpretation,
    };
  }

  factory DiagnosisFinding.fromJson(Map<String, dynamic> json) {
    return DiagnosisFinding(
      label: json['label'] as String? ?? 'Unspecified finding',
      source: json['source'] as String? ?? 'clinical',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      interpretation:
          json['interpretation'] as String? ??
          AppStrings.t('diagnosis_default_finding_interpretation'),
    );
  }
}

class DiagnosisReport {
  final String primaryDiagnosis;
  final String diagnosticStatement;
  final double confidence;
  final int severityIndex;
  final int urgencyIndex;
  final bool isContagious;
  final bool requiresVeterinarian;
  final String reasoning;
  final List<DiagnosisFinding> findings;
  final List<String> differentialDiagnoses;
  final List<String> immediateActions;
  final List<String> treatmentProtocol;
  final List<String> isolationMeasures;
  final List<String> monitoringPlan;
  final DateTime generatedAt;

  DiagnosisReport({
    required this.primaryDiagnosis,
    required this.diagnosticStatement,
    required this.confidence,
    required this.severityIndex,
    required this.urgencyIndex,
    required this.isContagious,
    required this.requiresVeterinarian,
    required this.reasoning,
    required this.findings,
    required this.differentialDiagnoses,
    required this.immediateActions,
    required this.treatmentProtocol,
    required this.isolationMeasures,
    required this.monitoringPlan,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'primary_diagnosis': primaryDiagnosis,
      'diagnostic_statement': diagnosticStatement,
      'confidence': confidence,
      'severity_index': severityIndex,
      'urgency_index': urgencyIndex,
      'is_contagious': isContagious,
      'requires_veterinarian': requiresVeterinarian,
      'reasoning': reasoning,
      'findings': findings.map((item) => item.toJson()).toList(),
      'differential_diagnoses': differentialDiagnoses,
      'immediate_actions': immediateActions,
      'treatment_protocol': treatmentProtocol,
      'isolation_measures': isolationMeasures,
      'monitoring_plan': monitoringPlan,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  factory DiagnosisReport.fromJson(Map<String, dynamic> json) {
    return DiagnosisReport(
      primaryDiagnosis:
          json['primary_diagnosis'] as String? ??
          AppStrings.t('diagnosis_preliminary_name'),
      diagnosticStatement:
          json['diagnostic_statement'] as String? ??
          AppStrings.t('diagnosis_default_statement'),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      severityIndex: (json['severity_index'] as num?)?.toInt() ?? 20,
      urgencyIndex: (json['urgency_index'] as num?)?.toInt() ?? 25,
      isContagious: json['is_contagious'] as bool? ?? false,
      requiresVeterinarian:
          json['requires_veterinarian'] as bool? ?? false,
      reasoning:
          json['reasoning'] as String? ??
          AppStrings.t('diagnosis_default_reasoning'),
      findings:
          (json['findings'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(DiagnosisFinding.fromJson)
              .toList(),
      differentialDiagnoses:
          (json['differential_diagnoses'] as List<dynamic>? ?? [])
              .map((item) => item.toString())
              .toList(),
      immediateActions:
          (json['immediate_actions'] as List<dynamic>? ?? [])
              .map((item) => item.toString())
              .toList(),
      treatmentProtocol:
          (json['treatment_protocol'] as List<dynamic>? ?? [])
              .map((item) => item.toString())
              .toList(),
      isolationMeasures:
          (json['isolation_measures'] as List<dynamic>? ?? [])
              .map((item) => item.toString())
              .toList(),
      monitoringPlan:
          (json['monitoring_plan'] as List<dynamic>? ?? [])
              .map((item) => item.toString())
              .toList(),
      generatedAt: DateTime.tryParse(json['generated_at'] as String? ?? ''),
    );
  }

  String toMedicalRecordSummary() {
    final buffer = StringBuffer()
      ..writeln(diagnosticStatement)
      ..writeln('${AppStrings.t('diagnosis_severity')}: $severityIndex/100')
      ..writeln('${AppStrings.t('diagnosis_urgency')}: $urgencyIndex/100')
      ..writeln(
        '${AppStrings.t('diagnosis_contagion')}: '
        '${isContagious ? AppStrings.t('yes') : AppStrings.t('no')}',
      )
      ..writeln('${AppStrings.t('diagnosis_reasoning')}: $reasoning');

    if (immediateActions.isNotEmpty) {
      buffer.writeln(
        '${AppStrings.t('diagnosis_immediate_actions')}: ${immediateActions.join(", ")}',
      );
    }

    if (treatmentProtocol.isNotEmpty) {
      buffer.writeln(
        '${AppStrings.t('diagnosis_treatment')}: ${treatmentProtocol.join(", ")}',
      );
    }

    if (isolationMeasures.isNotEmpty) {
      buffer.writeln(
        '${AppStrings.t('diagnosis_isolation')}: ${isolationMeasures.join(", ")}',
      );
    }

    return buffer.toString().trim();
  }

  Map<String, dynamic> toSupabasePayload({
    required String id,
    required String animalId,
    required String userId,
    String? imageUrl,
    String? clinicianNote,
  }) {
    return {
      'id': id,
      'animal_id': animalId,
      'user_id': userId,
      'diagnosis': clinicianNote?.trim().isNotEmpty == true
          ? clinicianNote!.trim()
          : diagnosticStatement,
      'ai_result': jsonEncode(toJson()),
      'image_url': imageUrl,
      'created_at': generatedAt.toIso8601String(),
    };
  }
}

class DiagnosisResponse {
  final DiagnosisStatus status;
  final DiagnosisNextStep nextStep;
  final DiagnosisReport? report;

  const DiagnosisResponse({
    required this.status,
    required this.nextStep,
    this.report,
  });

  bool get isCompleted => status == DiagnosisStatus.completed && report != null;
}
