import '../../network/network_info.dart';
import '../models/diagnosis_request.dart';
import '../models/diagnosis_response.dart';
import 'deep_learning_evidence_processor.dart';

class LivestockDiagnosisService {
  final NetworkInfo networkInfo;
  final DeepLearningEvidenceProcessor evidenceProcessor;

  const LivestockDiagnosisService({
    required this.networkInfo,
    this.evidenceProcessor = const LivestockEvidenceProcessor(),
  });

  /// Evalúa qué debe pedir primero la app antes de ejecutar el análisis.
  Future<DiagnosisResponse> prepare(DiagnosisRequest request) async {
    if (!await networkInfo.isConnected) {
      return DiagnosisResponse(
        status: DiagnosisStatus.needsInternet,
        nextStep: const DiagnosisNextStep(
          status: DiagnosisStatus.needsInternet,
          title: 'Se necesita internet',
          message:
              'El diagnóstico inteligente requiere conexión. Mientras vuelves a tener internet, revisa el historial médico o la ficha del animal.',
          canContinueOffline: true,
          suggestedRoutes: ['medical_history', 'animals_page'],
        ),
      );
    }

    if (!request.hasClinicalQuestion && !request.hasSymptoms) {
      return DiagnosisResponse(
        status: DiagnosisStatus.needsClinicalQuestion,
        nextStep: const DiagnosisNextStep(
          status: DiagnosisStatus.needsClinicalQuestion,
          title: 'Primero describe el caso',
          message:
              'Antes de pedir foto o cámara, la app debe preguntarle al usuario qué le preocupa del animal y qué síntomas observa.',
        ),
      );
    }

    final evidence = await evidenceProcessor.process(request);
    final topScore = _findTopCandidate(evidence.diseaseScores).$2;

    if (evidence.visualEvidenceRecommended &&
        !request.hasVisualEvidence &&
        topScore < 0.62) {
      return DiagnosisResponse(
        status: DiagnosisStatus.needsVisualEvidence,
        nextStep: const DiagnosisNextStep(
          status: DiagnosisStatus.needsVisualEvidence,
          title: 'Ahora pide evidencia visual',
          message:
              'Con la información clínica actual conviene solicitar una foto o abrir la cámara para confirmar lesiones visibles.',
        ),
      );
    }

    return DiagnosisResponse(
      status: DiagnosisStatus.readyToAnalyze,
      nextStep: const DiagnosisNextStep(
        status: DiagnosisStatus.readyToAnalyze,
        title: 'Listo para analizar',
        message:
            'Ya hay suficiente información clínica para ejecutar el razonamiento del motor de diagnóstico.',
      ),
    );
  }

  /// Ejecuta el diagnóstico completo y devuelve una salida lista para UI y BD.
  Future<DiagnosisResponse> analyze(DiagnosisRequest request) async {
    final preparation = await prepare(request);
    if (preparation.status != DiagnosisStatus.readyToAnalyze) {
      return preparation;
    }

    final evidence = await evidenceProcessor.process(request);
    final sortedCandidates = evidence.diseaseScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final primary = sortedCandidates.first;
    if (primary.value < 0.15) {
      final report = DiagnosisReport(
        primaryDiagnosis: 'evaluacion_inconclusa',
        diagnosticStatement:
            'La IA no encontró evidencia suficiente para emitir un diagnóstico confiable todavía.',
        confidence: double.parse(primary.value.toStringAsFixed(2)),
        severityIndex: 20,
        urgencyIndex: 25,
        isContagious: false,
        requiresVeterinarian: false,
        reasoning:
            'Los síntomas seleccionados no forman un patrón clínico fuerte. Se recomienda agregar más evidencia estructurada o una foto del síntoma.',
        findings: _buildFallbackFindings(request),
        differentialDiagnoses: const [],
        immediateActions: const [
          'Completar más síntomas de la encuesta.',
          'Agregar evidencia visual con la cámara si el caso tiene lesiones visibles.',
          'Si el animal empeora, solicitar valoración veterinaria.',
        ],
        treatmentProtocol: const [
          'No iniciar un tratamiento específico hasta tener evidencia clínica más clara.',
        ],
        isolationMeasures: const [],
        monitoringPlan: const [
          'Seguir observando el animal y registrar nuevos signos clínicos.',
        ],
      );

      return DiagnosisResponse(
        status: DiagnosisStatus.completed,
        nextStep: const DiagnosisNextStep(
          status: DiagnosisStatus.completed,
          title: 'Resultado preliminar',
          message:
              'La IA no encontró evidencia suficiente y devolvió un resultado preliminar en lugar de una enfermedad específica.',
        ),
        report: report,
      );
    }

    final secondary = sortedCandidates
        .skip(1)
        .take(2)
        .map((item) => item.key)
        .toList();

    final severity = _calculateSeverity(
      disease: primary.key,
      score: primary.value,
      request: request,
    );
    final urgency = _calculateUrgency(
      disease: primary.key,
      severity: severity,
      request: request,
    );
    final contagious = _isContagious(primary.key);
    final report = DiagnosisReport(
      primaryDiagnosis: primary.key,
      diagnosticStatement: _buildDiagnosticStatement(
        primary.key,
        primary.value,
      ),
      confidence: double.parse(primary.value.toStringAsFixed(2)),
      severityIndex: severity,
      urgencyIndex: urgency,
      isContagious: contagious,
      requiresVeterinarian: urgency >= 70 || severity >= 75,
      reasoning: _buildReasoning(
        disease: primary.key,
        findings: evidence.findings,
        request: request,
      ),
      findings: evidence.findings.isEmpty
          ? _buildFallbackFindings(request)
          : evidence.findings,
      differentialDiagnoses: secondary,
      immediateActions: _buildImmediateActions(primary.key, request),
      treatmentProtocol: _buildTreatmentProtocol(primary.key),
      isolationMeasures: contagious
          ? _buildIsolationMeasures(primary.key)
          : const [],
      monitoringPlan: _buildMonitoringPlan(primary.key, severity),
    );

    return DiagnosisResponse(
      status: DiagnosisStatus.completed,
      nextStep: const DiagnosisNextStep(
        status: DiagnosisStatus.completed,
        title: 'Diagnóstico completado',
        message:
            'El motor ya generó un informe estructurado listo para mostrarse al usuario o guardarse en Supabase.',
      ),
      report: report,
    );
  }

  (String, double) _findTopCandidate(Map<String, double> scores) {
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final winner = sortedEntries.isEmpty
        ? const MapEntry('sin hallazgos claros', 0.0)
        : sortedEntries.first;
    return (winner.key, winner.value);
  }

  int _calculateSeverity({
    required String disease,
    required double score,
    required DiagnosisRequest request,
  }) {
    var severity = (score * 55).round();

    if (request.temperature != null) {
      if (request.temperature! >= 40.5) {
        severity += 25;
      } else if (request.temperature! >= 39.5) {
        severity += 15;
      }
    }

    final normalizedSymptoms = request.reportedSymptoms
        .map((item) => item.toLowerCase())
        .join(' ');

    if (normalizedSymptoms.contains('dificultad respiratoria') ||
        normalizedSymptoms.contains('labored breathing') ||
        normalizedSymptoms.contains('deshidratacion') ||
        normalizedSymptoms.contains('dehydration')) {
      severity += 15;
    }

    if (disease == 'fiebre aftosa') {
      severity += 10;
    }

    return severity.clamp(20, 100);
  }

  int _calculateUrgency({
    required String disease,
    required int severity,
    required DiagnosisRequest request,
  }) {
    var urgency = severity;

    if (_isContagious(disease)) {
      urgency += 12;
    }

    if (request.temperature != null && request.temperature! >= 40.0) {
      urgency += 8;
    }

    if (disease == 'neumonia bovina' || disease == 'fiebre aftosa') {
      urgency += 10;
    }

    return urgency.clamp(25, 100);
  }

  bool _isContagious(String disease) {
    return disease == 'fiebre aftosa' ||
        disease == 'dermatofitosis' ||
        disease == 'neumonia bovina';
  }

  String _buildDiagnosticStatement(String disease, double score) {
    final confidence = (score * 100).round();
    switch (disease) {
      case 'mastitis':
        return 'Posible Mastitis detectada con una confianza estimada del $confidence%.';
      case 'fiebre aftosa':
        return 'Posible Fiebre Aftosa detectada con una confianza estimada del $confidence%.';
      case 'neumonia bovina':
        return 'Posible Neumonía bovina detectada con una confianza estimada del $confidence%.';
      case 'dermatofitosis':
        return 'Posible Dermatofitosis detectada con una confianza estimada del $confidence%.';
      case 'gastroenteritis':
        return 'Posible Gastroenteritis detectada con una confianza estimada del $confidence%.';
      default:
        return 'El sistema identificó un cuadro clínico inespecífico que requiere evaluación veterinaria.';
    }
  }

  String _buildReasoning({
    required String disease,
    required List<DiagnosisFinding> findings,
    required DiagnosisRequest request,
  }) {
    final base = switch (disease) {
      'mastitis' =>
        'La combinación de alteraciones en ubre, cambios en la leche y fiebre es compatible con inflamación mamaria.',
      'fiebre aftosa' =>
        'La presencia de lesiones orales o podales junto con fiebre alta sugiere una enfermedad vesicular contagiosa.',
      'neumonia bovina' =>
        'Los signos respiratorios y la elevación térmica orientan a un proceso infeccioso del tracto respiratorio.',
      'dermatofitosis' =>
        'Las lesiones cutáneas circulares y la pérdida de pelo son compatibles con una micosis superficial contagiosa.',
      'gastroenteritis' =>
        'La diarrea, debilidad y signos de deshidratación sugieren un compromiso digestivo agudo.',
      _ =>
        'La evidencia disponible no es suficiente para una clasificación específica.',
    };

    final evidenceSummary = findings.isEmpty
        ? 'El sistema razonó principalmente con síntomas y signos vitales reportados.'
        : 'Se consolidaron ${findings.length} hallazgos clínicos/visuales relevantes.';

    final vitalSummary = request.temperature != null
        ? ' Temperatura reportada: ${request.temperature} °C.'
        : '';

    return '$base $evidenceSummary$vitalSummary'.trim();
  }

  List<DiagnosisFinding> _buildFallbackFindings(DiagnosisRequest request) {
    final fallback = <DiagnosisFinding>[];

    for (final symptom in request.reportedSymptoms.take(4)) {
      fallback.add(
        DiagnosisFinding(
          label: symptom,
          source: 'clinical',
          confidence: 0.6,
          interpretation:
              'Síntoma reportado por el usuario y usado en el razonamiento.',
        ),
      );
    }

    if (request.temperature != null) {
      fallback.add(
        DiagnosisFinding(
          label: 'temperatura ${request.temperature} °C',
          source: 'vital_sign',
          confidence: 0.82,
          interpretation:
              'Valor térmico incorporado para estimar severidad y urgencia.',
        ),
      );
    }

    return fallback;
  }

  List<String> _buildImmediateActions(
    String disease,
    DiagnosisRequest request,
  ) {
    final base = <String>[
      'Registrar el caso en el historial clínico del animal.',
      'Vigilar cambios durante las próximas 6 a 12 horas.',
    ];

    switch (disease) {
      case 'mastitis':
        return [
          ...base,
          'Separar la leche afectada y no mezclarla con producción sana.',
          'Revisar dolor, calor y endurecimiento de la ubre.',
        ];
      case 'fiebre aftosa':
        return [
          ...base,
          'Activar aislamiento inmediato del animal.',
          'Limitar movimiento del lote y desinfectar superficies de contacto.',
        ];
      case 'neumonia bovina':
        return [
          ...base,
          'Reducir estrés, corrientes de aire y hacinamiento.',
          'Controlar frecuencia respiratoria y apetito.',
        ];
      case 'dermatofitosis':
        return [
          ...base,
          'Evitar compartir cepillos, sogas o implementos.',
          'Inspeccionar lesiones similares en otros animales.',
        ];
      case 'gastroenteritis':
        return [
          ...base,
          'Iniciar soporte hídrico inmediato.',
          'Controlar consistencia de heces y signos de debilidad.',
        ];
      default:
        return base;
    }
  }

  List<String> _buildTreatmentProtocol(String disease) {
    switch (disease) {
      case 'mastitis':
        return const [
          'Tomar muestra de leche si es posible antes del tratamiento.',
          'Consultar protocolo antibiótico intramamario según indicación veterinaria.',
          'Mantener higiene estricta antes y después del ordeño.',
        ];
      case 'fiebre aftosa':
        return const [
          'Notificar de inmediato al veterinario o autoridad sanitaria local.',
          'Aplicar soporte sintomático y control del dolor según indicación profesional.',
          'Restringir completamente la movilización del animal.',
        ];
      case 'neumonia bovina':
        return const [
          'Solicitar evaluación veterinaria temprana para terapia antimicrobiana.',
          'Mantener al animal en ambiente ventilado y seco.',
          'Asegurar acceso continuo a agua y soporte antiinflamatorio cuando corresponda.',
        ];
      case 'dermatofitosis':
        return const [
          'Usar tratamiento tópico antifúngico según disponibilidad y criterio veterinario.',
          'Desinfectar corrales, postes y herramientas de contacto frecuente.',
          'Mantener seguimiento del tamaño y número de lesiones.',
        ];
      case 'gastroenteritis':
        return const [
          'Administrar rehidratación oral o parenteral según gravedad.',
          'Corregir pérdidas electrolíticas.',
          'Solicitar apoyo veterinario si persiste diarrea intensa o decaimiento marcado.',
        ];
      default:
        return const [
          'Solicitar revisión veterinaria para confirmar el diagnóstico.',
        ];
    }
  }

  List<String> _buildIsolationMeasures(String disease) {
    switch (disease) {
      case 'fiebre aftosa':
        return const [
          'Aislar al animal en un área independiente y restringida.',
          'Prohibir ingreso y salida de animales hasta nueva evaluación.',
          'Desinfectar botas, manos y herramientas después de cada contacto.',
        ];
      case 'dermatofitosis':
        return const [
          'Separar al animal de corrales compartidos si las lesiones son activas.',
          'Usar guantes al manipular zonas afectadas.',
        ];
      case 'neumonia bovina':
        return const [
          'Evitar hacinamiento y separar animales con tos o secreción respiratoria.',
        ];
      default:
        return const [];
    }
  }

  List<String> _buildMonitoringPlan(String disease, int severity) {
    final frequency = severity >= 75 ? 'cada 4 horas' : 'cada 12 horas';

    switch (disease) {
      case 'mastitis':
        return [
          'Revisar evolución de la ubre y temperatura $frequency.',
          'Registrar cambios en color o consistencia de la leche.',
        ];
      case 'fiebre aftosa':
        return [
          'Controlar aparición de nuevas lesiones y estado general $frequency.',
          'Vigilar consumo de agua y dolor al caminar o comer.',
        ];
      case 'neumonia bovina':
        return [
          'Registrar frecuencia respiratoria, fiebre y apetito $frequency.',
        ];
      case 'dermatofitosis':
        return [
          'Observar extensión de las lesiones y respuesta al tratamiento cada 24 horas.',
        ];
      case 'gastroenteritis':
        return ['Controlar hidratación, heces y estado de ánimo $frequency.'];
      default:
        return [
          'Mantener seguimiento clínico hasta contar con una valoración presencial.',
        ];
    }
  }
}
