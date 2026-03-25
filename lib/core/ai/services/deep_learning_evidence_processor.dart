import '../models/diagnosis_request.dart';
import '../models/diagnosis_response.dart';

/// Resultado intermedio de la capa que procesa evidencia.
class EvidenceProcessingResult {
  final Map<String, double> diseaseScores;
  final List<DiagnosisFinding> findings;
  final bool visualEvidenceRecommended;

  const EvidenceProcessingResult({
    required this.diseaseScores,
    required this.findings,
    required this.visualEvidenceRecommended,
  });
}

abstract class DeepLearningEvidenceProcessor {
  Future<EvidenceProcessingResult> process(DiagnosisRequest request);
}

/// Implementación inicial que deja preparada la capa de inferencia.
/// Aquí luego podremos conectar TFLite, APIs o embeddings sin cambiar
/// el contrato del motor de diagnóstico.
class LivestockEvidenceProcessor implements DeepLearningEvidenceProcessor {
  const LivestockEvidenceProcessor();

  static const Map<String, List<String>> _diseaseKeywords = {
    'mastitis': [
      'mastitis',
      'ubre inflamada',
      'ubre caliente',
      'dolor en ubre',
      'leche grumosa',
      'secrecion mamaria',
      'swollen udder',
      'udder inflammation',
      'milk clots',
    ],
    'fiebre aftosa': [
      'fiebre aftosa',
      'vesiculas',
      'llagas en boca',
      'cojera',
      'babeo',
      'lesiones pezuñas',
      'mouth lesions',
      'hoof lesions',
      'drooling',
      'limping',
    ],
    'neumonia bovina': [
      'tos',
      'secrecion nasal',
      'dificultad respiratoria',
      'respiracion rapida',
      'cough',
      'nasal discharge',
      'labored breathing',
    ],
    'dermatofitosis': [
      'lesiones en piel',
      'caida de pelo',
      'manchas circulares',
      'costras',
      'skin lesions',
      'hair loss',
      'ring lesions',
    ],
    'gastroenteritis': [
      'diarrea',
      'deshidratacion',
      'ojos hundidos',
      'debilidad',
      'diarrhea',
      'dehydration',
      'weakness',
    ],
  };

  @override
  Future<EvidenceProcessingResult> process(DiagnosisRequest request) async {
    final diseaseScores = <String, double>{};
    final findings = <DiagnosisFinding>[];
    final normalizedSignals = [
      request.clinicalQuestion,
      ...request.reportedSymptoms,
      ...request.visualFindings,
    ].map(_normalize).where((item) => item.isNotEmpty).toList();

    for (final entry in _diseaseKeywords.entries) {
      var score = 0.0;

      for (final keyword in entry.value) {
        if (normalizedSignals.any(
          (signal) => signal.contains(_normalize(keyword)),
        )) {
          score += 0.18;
          findings.add(
            DiagnosisFinding(
              label: keyword,
              source:
                  request.visualFindings.any(
                    (visualFinding) =>
                        _normalize(visualFinding).contains(_normalize(keyword)),
                  )
                  ? 'vision'
                  : 'clinical',
              confidence: 0.72,
              interpretation: 'Patrón compatible con ${entry.key}.',
            ),
          );
        }
      }

      if (request.temperature != null) {
        if (entry.key == 'mastitis' && request.temperature! >= 39.7) {
          score += 0.12;
        }
        if (entry.key == 'fiebre aftosa' && request.temperature! >= 40.0) {
          score += 0.18;
        }
        if (entry.key == 'neumonia bovina' && request.temperature! >= 39.5) {
          score += 0.15;
        }
        if (entry.key == 'gastroenteritis' && request.temperature! >= 39.2) {
          score += 0.08;
        }
      }

      diseaseScores[entry.key] = score.clamp(0.0, 0.98).toDouble();
    }

    final visualEvidenceRecommended = normalizedSignals.any(
      (signal) =>
          signal.contains('piel') ||
          signal.contains('skin') ||
          signal.contains('ubre') ||
          signal.contains('udder') ||
          signal.contains('lesion') ||
          signal.contains('lesión') ||
          signal.contains('pezu') ||
          signal.contains('hoof'),
    );

    return EvidenceProcessingResult(
      diseaseScores: diseaseScores,
      findings: findings,
      visualEvidenceRecommended: visualEvidenceRecommended,
    );
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}
