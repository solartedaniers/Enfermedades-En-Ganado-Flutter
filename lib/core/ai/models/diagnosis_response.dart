import 'dart:convert';

enum DiagnosisStatus {
  needsInternet,
  needsClinicalQuestion,
  needsVisualEvidence,
  readyToAnalyze,
  completed,
}

/// Define la siguiente acción que la UI debe solicitar al usuario.
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

/// Hallazgo individual identificado por la etapa de análisis.
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
}

/// Salida integral del motor experto.
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

  /// Mantiene compatibilidad con el campo textual `ai_result` actual.
  String toMedicalRecordSummary() {
    final buffer = StringBuffer()
      ..writeln(diagnosticStatement)
      ..writeln('Severidad: $severityIndex/100')
      ..writeln('Urgencia: $urgencyIndex/100')
      ..writeln('Contagiosa: ${isContagious ? "Sí" : "No"}')
      ..writeln('Razonamiento: $reasoning');

    if (immediateActions.isNotEmpty) {
      buffer.writeln('Acciones inmediatas: ${immediateActions.join(", ")}');
    }

    if (treatmentProtocol.isNotEmpty) {
      buffer.writeln('Tratamiento: ${treatmentProtocol.join(", ")}');
    }

    if (isolationMeasures.isNotEmpty) {
      buffer.writeln('Aislamiento: ${isolationMeasures.join(", ")}');
    }

    return buffer.toString().trim();
  }

  /// Deja un payload estructurado listo para la tabla de historial médico.
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

/// Respuesta completa del servicio.
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
