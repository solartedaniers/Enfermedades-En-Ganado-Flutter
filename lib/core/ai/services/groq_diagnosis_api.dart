import 'dart:convert';
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
        findings: _parseFindings(reportJson['findings']),
        differentialDiagnoses: List<String>.from(reportJson['differential_diagnoses'] ?? []),
        immediateActions: List<String>.from(reportJson['immediate_actions'] ?? []),
        treatmentProtocol: List<String>.from(reportJson['treatment_protocol'] ?? []),
        isolationMeasures: List<String>.from(reportJson['isolation_measures'] ?? []),
        monitoringPlan: List<String>.from(reportJson['monitoring_plan'] ?? []),
      );
    } on SocketException {
      throw Exception('Sin conexión a internet para el diagnóstico.');
    } catch (e) {
      // Importante: esto nos dirá en consola si el JSON venía mal
      print('DEBUG GROQ ERROR: $e');
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
    return '''Eres AgroVet AI, un experto en medicina veterinaria bovina y porcina. 
    Tu tarea es generar un diagnóstico profesional en formato JSON. 
    Es OBLIGATORIO que el JSON contenga exactamente estas llaves:
    {
      "primary_diagnosis": "nombre",
      "diagnostic_statement": "resumen corto",
      "confidence": 0.95,
      "severity_index": 80,
      "urgency_index": 70,
      "is_contagious": true,
      "requires_veterinarian": true,
      "reasoning": "explicación detallada",
      "findings": [{"label": "síntoma", "source": "visual", "confidence": 0.9, "interpretation": "significado"}],
      "differential_diagnoses": ["enf1", "enf2"],
      "immediate_actions": ["accion1"],
      "treatment_protocol": ["paso1"],
      "isolation_measures": ["medida1"],
      "monitoring_plan": ["plan1"]
    }''';
  }

  String _buildCasePrompt(DiagnosisRequest request) {
    return '''Analiza el siguiente caso clínico:
    - Especie: ${request.species}
    - Síntomas reportados: ${request.reportedSymptoms.join(", ")}
    - Hallazgos visuales: ${request.visualFindings.join(", ")}
    - Pregunta del usuario: ${request.clinicalQuestion ?? "No provista"}''';
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