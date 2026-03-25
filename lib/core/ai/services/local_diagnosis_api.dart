import '../models/diagnosis_request.dart';
import '../models/diagnosis_response.dart';
import 'deep_learning_evidence_processor.dart';

/// Motor local de respaldo para no dejar la app sin diagnostico.
///
/// No depende de APIs externas y usa reglas clinicas simples sobre los
/// sintomas reportados. Sirve como fallback cuando la IA remota no esta
/// disponible o se queda sin cuota.
class LocalDiagnosisApi {
  final DeepLearningEvidenceProcessor processor;

  const LocalDiagnosisApi({
    this.processor = const LivestockEvidenceProcessor(),
  });

  Future<DiagnosisReport> createDiagnosisReport(DiagnosisRequest request) async {
    final result = await processor.process(request);
    final ranked = result.diseaseScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = ranked.isNotEmpty ? ranked.first : null;
    final topScore = top?.value ?? 0.0;
    final primaryDiagnosis = _formatDiseaseName(top?.key ?? 'caso preliminar');
    final confidence = _confidenceFor(topScore, request);
    final severity = _severityFor(top?.key, topScore, request.temperature);
    final urgency = _urgencyFor(top?.key, topScore, request.temperature);
    final isContagious = _isContagious(top?.key);
    final requiresVeterinarian =
        urgency >= 70 || severity >= 75 || topScore < 0.35;

    final statement = topScore >= 0.35
        ? 'Posible $primaryDiagnosis detectada con base en los sintomas reportados.'
        : 'Caso preliminar: la evidencia actual no permite confirmar una enfermedad concreta.';

    final reasoning = _buildReasoning(
      request: request,
      primaryDiagnosis: primaryDiagnosis,
      topScore: topScore,
      findings: result.findings,
      usedVisualRecommendation: result.visualEvidenceRecommended,
    );

    return DiagnosisReport(
      primaryDiagnosis: primaryDiagnosis,
      diagnosticStatement: statement,
      confidence: confidence,
      severityIndex: severity,
      urgencyIndex: urgency,
      isContagious: isContagious,
      requiresVeterinarian: requiresVeterinarian,
      reasoning: reasoning,
      findings: result.findings.isNotEmpty
          ? result.findings
          : const [
              DiagnosisFinding(
                label: 'Evaluacion clinica inicial',
                source: 'clinical',
                confidence: 0.55,
                interpretation:
                    'El motor local analizo sintomas y datos basicos del animal.',
              ),
            ],
      differentialDiagnoses: ranked
          .skip(1)
          .take(3)
          .where((entry) => entry.value > 0.1)
          .map((entry) => _formatDiseaseName(entry.key))
          .toList(),
      immediateActions: _buildImmediateActions(top?.key, request),
      treatmentProtocol: _buildTreatmentProtocol(top?.key),
      isolationMeasures: isContagious ? _buildIsolationMeasures(top?.key) : const [],
      monitoringPlan: _buildMonitoringPlan(top?.key, request.temperature),
    );
  }

  String _buildReasoning({
    required DiagnosisRequest request,
    required String primaryDiagnosis,
    required double topScore,
    required List<DiagnosisFinding> findings,
    required bool usedVisualRecommendation,
  }) {
    final signalCount = [
      request.clinicalQuestion,
      ...request.reportedSymptoms,
      ...request.visualFindings,
    ].where((item) => item.trim().isNotEmpty).length;

    if (topScore < 0.35) {
      return 'La evidencia actual es limitada para confirmar una enfermedad especifica. '
          'El motor local encontro $signalCount señales utiles, pero recomienda complementar '
          'con mas sintomas, exploracion fisica o una imagen si hay lesiones visibles.';
    }

    final evidenceSummary = findings.isEmpty
        ? 'sintomas generales reportados por el usuario'
        : findings.take(3).map((item) => item.label).join(', ');

    final visualAdvice = usedVisualRecommendation
        ? ' Se recomienda agregar foto si existen lesiones visibles para afinar el caso.'
        : '';

    return 'El motor local identifico patrones compatibles con $primaryDiagnosis '
        'a partir de $evidenceSummary.$visualAdvice';
  }

  List<String> _buildImmediateActions(String? diseaseKey, DiagnosisRequest request) {
    final actions = <String>[
      'Registrar el caso en el historial clinico del animal.',
      'Mantener observacion cercana durante las proximas 12 horas.',
    ];

    if ((request.temperature ?? 0) >= 39.5) {
      actions.add('Vigilar fiebre y repetir toma de temperatura.');
    }

    switch (diseaseKey) {
      case 'mastitis':
        actions.addAll([
          'Revisar calor, dolor y endurecimiento de la ubre.',
          'Separar la leche afectada y no mezclarla con produccion sana.',
        ]);
        break;
      case 'fiebre aftosa':
        actions.addAll([
          'Separar al animal del resto del lote.',
          'Evitar movimiento del animal hasta revision veterinaria.',
        ]);
        break;
      case 'neumonia bovina':
        actions.addAll([
          'Reducir el estres y mantener buena ventilacion.',
          'Observar frecuencia respiratoria y apetito.',
        ]);
        break;
      case 'gastroenteritis':
        actions.addAll([
          'Evaluar hidratacion y disponibilidad de agua limpia.',
          'Revisar consistencia de heces y frecuencia.',
        ]);
        break;
      default:
        actions.add('Completar mas evidencia clinica si el cuadro persiste.');
    }

    return actions;
  }

  List<String> _buildTreatmentProtocol(String? diseaseKey) {
    switch (diseaseKey) {
      case 'mastitis':
        return const [
          'Tomar muestra de leche si es posible antes del tratamiento.',
          'Consultar protocolo intramamario segun indicacion veterinaria.',
          'Mantener higiene estricta antes y despues del ordeño.',
        ];
      case 'fiebre aftosa':
        return const [
          'Notificar rapidamente a un veterinario o autoridad sanitaria.',
          'Aplicar manejo de soporte y control del dolor solo bajo indicacion profesional.',
        ];
      case 'neumonia bovina':
        return const [
          'Consultar manejo antiinflamatorio y antibiotico segun revision veterinaria.',
          'Favorecer descanso, agua y ambiente seco.',
        ];
      case 'gastroenteritis':
        return const [
          'Priorizar rehidratacion y soporte electrolitico.',
          'Evaluar dieta reciente y posible cambio de alimento.',
        ];
      default:
        return const [
          'Usar este resultado como orientacion inicial y complementar con revision clinica.',
        ];
    }
  }

  List<String> _buildIsolationMeasures(String? diseaseKey) {
    switch (diseaseKey) {
      case 'fiebre aftosa':
        return const [
          'Aislar al animal del resto del lote.',
          'Desinfectar botas, manos y utensilios despues del contacto.',
          'Evitar compartir comederos y bebederos.',
        ];
      default:
        return const [
          'Mantener vigilancia sanitaria si aparecen mas animales con signos similares.',
        ];
    }
  }

  List<String> _buildMonitoringPlan(String? diseaseKey, double? temperature) {
    final plan = <String>[
      'Registrar cambios clinicos cada 12 horas.',
      'Comparar evolucion del apetito, energia y movilidad.',
    ];

    if (temperature != null) {
      plan.add('Repetir temperatura y compararla con el valor actual.');
    }

    if (diseaseKey == 'mastitis') {
      plan.add('Observar cambios en la leche y en la inflamacion de la ubre.');
    }

    if (diseaseKey == 'neumonia bovina') {
      plan.add('Controlar tos, secrecion nasal y esfuerzo respiratorio.');
    }

    return plan;
  }

  double _confidenceFor(double topScore, DiagnosisRequest request) {
    final signalBoost = request.reportedSymptoms.length * 0.03;
    return (topScore + signalBoost).clamp(0.22, 0.93);
  }

  int _severityFor(String? diseaseKey, double topScore, double? temperature) {
    var base = (topScore * 100).round();
    if ((temperature ?? 0) >= 40.0) {
      base += 12;
    }
    if (diseaseKey == 'fiebre aftosa') {
      base += 15;
    }
    return base.clamp(20, 95);
  }

  int _urgencyFor(String? diseaseKey, double topScore, double? temperature) {
    var base = ((topScore * 100) + 10).round();
    if ((temperature ?? 0) >= 39.8) {
      base += 10;
    }
    if (diseaseKey == 'fiebre aftosa' || diseaseKey == 'neumonia bovina') {
      base += 15;
    }
    return base.clamp(25, 98);
  }

  bool _isContagious(String? diseaseKey) {
    return diseaseKey == 'fiebre aftosa';
  }

  String _formatDiseaseName(String diseaseKey) {
    switch (diseaseKey) {
      case 'mastitis':
        return 'mastitis';
      case 'fiebre aftosa':
        return 'fiebre aftosa';
      case 'neumonia bovina':
        return 'neumonia bovina';
      case 'dermatofitosis':
        return 'dermatofitosis';
      case 'gastroenteritis':
        return 'gastroenteritis';
      default:
        return 'evaluacion preliminar';
    }
  }
}
