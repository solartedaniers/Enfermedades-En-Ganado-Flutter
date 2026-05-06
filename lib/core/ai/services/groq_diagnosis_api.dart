import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/diagnosis_request.dart';
import '../models/diagnosis_response.dart';

class GroqDiagnosisApi {
  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  
  // Usamos el modelo versatile que es excelente para JSON
  static const String _model = 'llama-3.3-70b-versatile';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  const GroqDiagnosisApi();

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<DiagnosisReport> createDiagnosisReport(DiagnosisRequest request) async {
    if (!isConfigured) {
      throw Exception('Falta configurar la GROQ_API_KEY en el archivo .env');
    }

    final client = HttpClient();

    try {
      final httpRequest = await client.postUrl(Uri.parse(_baseUrl));

      httpRequest.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey');
      httpRequest.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');

      final payload = _buildPayload(request);
      final payloadBytes = utf8.encode(jsonEncode(payload));
      
      httpRequest.add(payloadBytes);

      final httpResponse = await httpRequest.close();
      final responseBody = await utf8.decodeStream(httpResponse);

      if (httpResponse.statusCode >= 400) {
        throw Exception('Error en Groq (${httpResponse.statusCode}): $responseBody');
      }

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final outputText = decoded['choices'][0]['message']['content'] as String;
      
      // Limpieza de Markdown por si acaso
      final cleanJson = outputText.replaceAll('```json', '').replaceAll('```', '').trim();
      final reportJson = jsonDecode(cleanJson) as Map<String, dynamic>;

      return DiagnosisReport(
        primaryDiagnosis: reportJson['primary_diagnosis'] ?? 'Indeterminado',
        diagnosticStatement: reportJson['diagnostic_statement'] ?? 'Sin descripción.',
        confidence: (reportJson['confidence'] as num?)?.toDouble() ?? 0.0,
        severityIndex: (reportJson['severity_index'] as num?)?.toInt() ?? 0,
        urgencyIndex: (reportJson['urgency_index'] as num?)?.toInt() ?? 0,
        isContagious: reportJson['is_contagious'] ?? false,
        requiresVeterinarian: reportJson['requires_veterinarian'] ?? true,
        reasoning: reportJson['reasoning'] ?? '',
        symptomAnalysis: reportJson['symptom_analysis'] ?? '',
        validatedSpecies: reportJson['validated_species'] ?? request.species,
        visualDetectionConfidence: (reportJson['visual_detection_confidence'] as num?)?.toDouble() ?? 0.85,
        disclaimer:
            reportJson['disclaimer'] ??
                'Este análisis es una asistencia basada en IA. No sustituye la evaluación presencial de un Médico Veterinario. Se recomienda inspección clínica de un profesional colegiado.',
        findings: _parseFindings(reportJson['findings']),
        differentialDiagnoses: List<String>.from(reportJson['differential_diagnoses'] ?? []),
        immediateActions: List<String>.from(reportJson['immediate_actions'] ?? []),
        treatmentProtocol: List<String>.from(reportJson['preventive_suggestions'] ?? reportJson['treatment_protocol'] ?? []),
        isolationMeasures: List<String>.from(reportJson['isolation_measures'] ?? []),
        monitoringPlan: List<String>.from(reportJson['monitoring_plan'] ?? []),
      );
    } on SocketException {
      throw Exception('Sin conexión a internet para el diagnóstico.');
    } catch (e, stackTrace) {
      developer.log(
        'Error procesando respuesta de Groq',
        name: 'GroqDiagnosisApi',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Error procesando diagnóstico: $e');
    } finally {
      client.close();
    }
  }

  Map<String, dynamic> _buildPayload(DiagnosisRequest request) {
    return {
      'model': _model,
      'messages': [
        {'role': 'system', 'content': _buildSystemInstructions()},
        {'role': 'user', 'content': _buildCasePrompt(request)},
      ],
      'temperature': 0.1, // Aún más bajo para máxima estabilidad
      'response_format': {'type': 'json_object'},
    };
  }

  String _buildSystemInstructions() {
    return '''Eres AgroVet AI, un asistente veterinario analítico especializado en medicina de ganado bovino, porcino, equino, ovino y caprino.

PRINCIPIOS FUNDAMENTALES:
1. Análisis basado en HALLAZGOS VISUALES y síntomas clínicos
2. Usa LENGUAJE PROBABILÍSTICO: "Se observan patrones compatibles con...", "Existe una probabilidad del X% de...", "Los hallazgos sugieren..."
3. NUNCA afirmes diagnósticos absolutos. Siempre presuntivo y clínico.
4. Enfatiza HALLAZGOS VISUALES: coloración, textura, postura, simetría, movimiento, estado general
5. Interpreta síntomas en terminología veterinaria profesional

ESTRUCTURA DEL ANÁLISIS:
- Hallazgos Visuales: Describe patrones de color, textura, lesiones, inflamación, asimetría
- Análisis Clínico: Correlaciona síntomas con hallazgos visuales
- Interpretación: Traduce observaciones en diagnósticos diferenciales con probabilidades
- Recomendación Preventiva: Medidas de inmediato sin necesidad de veterinario

DETECCIÓN DE INCONSISTENCIAS:
Si detectas incoherencia especie-síntoma o información biológicamente absurda:
Responde en "diagnostic_statement": "Se detectó una inconsistencia en la información proporcionada. Verifique que la especie y síntomas sean compatibles."

OBLIGATORIO - Estructura JSON exacta:
{
  "primary_diagnosis": "nombre_enfermedad",
  "diagnostic_statement": "Análisis visual completado. Se observan patrones compatibles con... Los hallazgos sugieren una probabilidad del X% de...",
  "confidence": 0.75,
  "severity_index": 65,
  "urgency_index": 60,
  "is_contagious": true,
  "requires_veterinarian": true,
  "reasoning": "Análisis detallado de hallazgos visuales y correlación clínica",
  "symptom_analysis": "Traducción de síntomas a terminología veterinaria",
  "visual_findings": "Descripción de patrones visuales observados",
  "validated_species": "especie_registrada",
  "visual_detection_confidence": 0.82,
  "findings": [{"label": "hallazgo", "source": "visual", "confidence": 0.85, "interpretation": "significado"}],
  "differential_diagnoses": ["posibilidad_1", "posibilidad_2", "posibilidad_3"],
  "preventive_suggestions": ["sugerencia_preventiva_1", "sugerencia_preventiva_2"],
  "immediate_actions": ["acción_inmediata_1"],
  "monitoring_plan": ["monitoreo_1"],
  "disclaimer": "Este análisis es una asistencia basada en IA. No sustituye la evaluación presencial de un Médico Veterinario. Se recomienda inspección clínica de un profesional colegiado."
}

INSTRUCCIONES POR SECCIÓN:
- visual_findings: Detalla coloración, textura, lesiones, inflamación, asimetría, postura
- findings: Array de hallazgos clave (máx 5)
- differential_diagnoses: Ordena por probabilidad, incluye % mental (ej: "Sarna (65%)")
- preventive_suggestions: Medidas de mantenimiento y prevención SIN diagnóstico específico
- confidence: Base en robustez visual y síntomas (0.4-0.95)
- severity_index: 0-100 (0=ninguno, 100=crítico)
- urgency_index: 0-100 (0=pueden esperar, 100=emergencia)
''';
  }

  String _buildCasePrompt(DiagnosisRequest request) {
    return '''Analiza el siguiente caso clínico utilizando HALLAZGOS VISUALES como evidencia principal:

INFORMACIÓN DEL ANIMAL:
- Nombre: ${request.animalName}
- Especie registrada: ${request.species}
- Edad/Condición: [Si está disponible en síntomas]

PREGUNTA CLÍNICA DEL USUARIO:
"${request.clinicalQuestion}"

SÍNTOMAS REPORTADOS:
${request.reportedSymptoms.isNotEmpty ? request.reportedSymptoms.join('\n') : 'Sin síntomas específicos reportados'}

HALLAZGOS VISUALES OBSERVADOS (de la imagen capturada):
${request.visualFindings.isNotEmpty ? request.visualFindings.join('\n') : 'Se capturó imagen para análisis visual'}

INSTRUCCIONES DE ANÁLISIS:
1. Correlaciona hallazgos visuales con síntomas reportados
2. Identifica patrones compatibles con condiciones clínicas
3. Expresa hallazgos con probabilidades (ej: "62% compatible con X")
4. Proporciona diagnósticos diferenciales ordenados por probabilidad
5. Incluye sugerencias preventivas específicas para la especie
6. Enfatiza que requiere evaluación veterinaria presencial''';
  }

  List<DiagnosisFinding> _parseFindings(dynamic raw) {
    if (raw == null || raw is! List) return [];
    return raw.map((item) => DiagnosisFinding(
      label: item['label'] ?? '',
      source: item['source'] ?? 'clinical',
      confidence: (item['confidence'] as num?)?.toDouble() ?? 0.0,
      interpretation: item['interpretation'] ?? '',
    )).toList();
  }
}
