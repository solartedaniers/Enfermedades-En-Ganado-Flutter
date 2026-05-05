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
    if (request.imageBytes != null && request.livestockDetection == null) {
      throw Exception(
        'El diagnostico remoto requiere una deteccion local de ganado validada.',
      );
    }

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
        validatedSpecies:
            reportJson['validated_species'] ?? request.livestockDetection?.species,
        visualDetectionConfidence:
            (reportJson['visual_detection_confidence'] as num?)?.toDouble() ??
                request.livestockDetection?.confidence,
        disclaimer:
            reportJson['disclaimer'] ??
                'Este informe es una asistencia basada en Inteligencia Artificial y no sustituye el juicio clinico de un Medico Veterinario. Se recomienda la inspeccion presencial de un profesional colegiado.',
        findings: _parseFindings(reportJson['findings']),
        differentialDiagnoses: List<String>.from(reportJson['differential_diagnoses'] ?? []),
        immediateActions: List<String>.from(reportJson['immediate_actions'] ?? []),
        treatmentProtocol: List<String>.from(reportJson['treatment_protocol'] ?? []),
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
    return '''Eres AgroVet AI, un experto en medicina veterinaria para ganado bovino, porcino, equino, ovino y caprino.
    Tu tarea es generar un informe tecnico profesional en formato JSON.
    No afirmes diagnosticos absolutos: usa lenguaje presuntivo y clinico.
    Si notas incoherencia especie-sintoma, responde en diagnostic_statement: "Existe una discrepancia entre la especie detectada o registrada y los sintomas descritos. Por favor verifique la informacion".
    Si el texto contiene afirmaciones biologicamente absurdas, fantasiosas o no clinicas, responde en diagnostic_statement: "Se ha detectado una inconsistencia en la descripcion de los sintomas. Por favor, ingrese informacion tecnica y real sobre el estado del animal".
    Es OBLIGATORIO que el JSON contenga exactamente estas llaves:
    {
      "primary_diagnosis": "nombre",
      "diagnostic_statement": "Basado en la evidencia visual y los sintomas descritos, el cuadro clinico es compatible con...",
      "confidence": 0.95,
      "severity_index": 80,
      "urgency_index": 70,
      "is_contagious": true,
      "requires_veterinarian": true,
      "reasoning": "explicacion detallada",
      "symptom_analysis": "interpretacion tecnica veterinaria de los sintomas escritos por el usuario",
      "validated_species": "especie validada por YOLO",
      "visual_detection_confidence": 0.91,
      "findings": [{"label": "sintoma", "source": "visual", "confidence": 0.9, "interpretation": "significado"}],
      "differential_diagnoses": ["enf1", "enf2"],
      "immediate_actions": ["accion1"],
      "treatment_protocol": ["medicamento o principio activo, dosis, via, frecuencia y duracion"],
      "isolation_measures": ["medida1"],
      "monitoring_plan": ["plan1"],
      "disclaimer": "Este informe es una asistencia basada en Inteligencia Artificial y no sustituye el juicio clinico de un Medico Veterinario. Se recomienda la inspeccion presencial de un profesional colegiado."
    }
    En symptom_analysis traduce lenguaje informal a terminologia veterinaria sin inventar signos no reportados.
    En treatment_protocol incluye medicamento o principio activo, dosis, via, frecuencia y duracion cuando sea seguro sugerirlos.
    Si no es seguro indicar una dosis exacta, dilo claramente y recomienda validarla con un veterinario.''';
  }

  String _buildCasePrompt(DiagnosisRequest request) {
    return '''Analiza el siguiente caso clínico:
    - Nombre del animal: ${request.animalName}
    - Especie registrada: ${request.species}
    - Especie validada por YOLO local: ${request.livestockDetection?.species ?? 'sin foto validada; usar especie registrada'}
    - Confianza YOLO: ${request.livestockDetection == null ? 'no aplica' : '${(request.livestockDetection!.confidence * 100).toStringAsFixed(1)}%'}
    - Síntomas reportados: ${request.reportedSymptoms.join(", ")}
    - Hallazgos visuales: ${request.visualFindings.join(", ")}
    - Pregunta del usuario: ${request.clinicalQuestion}''';
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
