import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import '../../utils/app_strings.dart';
import '../models/diagnosis_request.dart';
import '../models/diagnosis_response.dart';

/// Cliente directo para usar una IA real vía OpenAI Responses API.
///
/// Nota: para producción, lo ideal es mover esta llamada a un backend
/// o a una Edge Function. Aquí se deja directo para que el proyecto
/// funcione ya mismo usando `--dart-define`.
class OpenAIDiagnosisApi {
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String _model = String.fromEnvironment(
    'OPENAI_DIAGNOSIS_MODEL',
    defaultValue: 'gpt-4.1',
  );

  const OpenAIDiagnosisApi();

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<DiagnosisReport> createDiagnosisReport(DiagnosisRequest request) async {
    if (!isConfigured) {
      throw Exception(
        'Falta configurar OPENAI_API_KEY con --dart-define para usar el diagnóstico con IA real.',
      );
    }

    final client = HttpClient();

    try {
      final httpRequest = await client.postUrl(
        Uri.parse('https://api.openai.com/v1/responses'),
      );

      httpRequest.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey');
      httpRequest.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );
      final payloadBytes = utf8.encode(jsonEncode(_buildPayload(request)));
      httpRequest.headers.set(
        HttpHeaders.contentLengthHeader,
        payloadBytes.length.toString(),
      );
      httpRequest.add(payloadBytes);

      final httpResponse = await httpRequest.close();
      final responseBody = await utf8.decodeStream(httpResponse);

      if (httpResponse.statusCode >= 400) {
        throw Exception(_buildFriendlyError(httpResponse.statusCode, responseBody));
      }

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final outputText = _extractOutputText(decoded);
      final reportJson = jsonDecode(outputText) as Map<String, dynamic>;

      return DiagnosisReport(
        primaryDiagnosis: reportJson['primary_diagnosis'] as String? ?? 'indeterminado',
        diagnosticStatement:
            reportJson['diagnostic_statement'] as String? ??
            'La IA no devolvió un diagnóstico textual.',
        confidence: (reportJson['confidence'] as num?)?.toDouble() ?? 0.0,
        severityIndex: (reportJson['severity_index'] as num?)?.toInt() ?? 20,
        urgencyIndex: (reportJson['urgency_index'] as num?)?.toInt() ?? 25,
        isContagious: reportJson['is_contagious'] as bool? ?? false,
        requiresVeterinarian:
            reportJson['requires_veterinarian'] as bool? ?? false,
        reasoning:
            reportJson['reasoning'] as String? ??
            'La IA no devolvió razonamiento clínico.',
        findings: _parseFindings(reportJson['findings'] as List<dynamic>?),
        differentialDiagnoses:
            (reportJson['differential_diagnoses'] as List<dynamic>? ?? [])
                .map((item) => item.toString())
                .toList(),
        immediateActions:
            (reportJson['immediate_actions'] as List<dynamic>? ?? [])
                .map((item) => item.toString())
                .toList(),
        treatmentProtocol:
            (reportJson['treatment_protocol'] as List<dynamic>? ?? [])
                .map((item) => item.toString())
                .toList(),
        isolationMeasures:
            (reportJson['isolation_measures'] as List<dynamic>? ?? [])
                .map((item) => item.toString())
                .toList(),
        monitoringPlan:
            (reportJson['monitoring_plan'] as List<dynamic>? ?? [])
                .map((item) => item.toString())
                .toList(),
      );
    } on SocketException {
      throw Exception(
        'No se pudo conectar con la IA. Revisa tu conexión a internet e intenta de nuevo.',
      );
    } on FormatException {
      throw Exception(
        'La respuesta de la IA no llegó en un formato válido. Intenta de nuevo.',
      );
    } finally {
      client.close();
    }
  }

  String _buildFriendlyError(int statusCode, String responseBody) {
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final error = decoded['error'] as Map<String, dynamic>?;
      final code = error?['code']?.toString();
      final message = error?['message']?.toString();

      if (statusCode == 401 || code == 'invalid_api_key') {
        return 'La API key de OpenAI no es válida. Inicia la app con una clave real en OPENAI_API_KEY.';
      }

      if (statusCode == 429) {
        return 'La IA está temporalmente ocupada o alcanzaste el límite de uso. Intenta nuevamente en unos minutos.';
      }

      if (statusCode >= 500) {
        return 'OpenAI presentó un problema temporal. Intenta nuevamente en unos minutos.';
      }

      return message ?? 'Error OpenAI $statusCode';
    } catch (_) {
      return 'Error OpenAI $statusCode';
    }
  }

  Map<String, dynamic> _buildPayload(DiagnosisRequest request) {
    final content = <Map<String, dynamic>>[
      {
        'type': 'input_text',
        'text': _buildCasePrompt(request),
      },
    ];

    final imageDataUrl = _buildImageDataUrl(request.imageBytes);
    if (imageDataUrl != null) {
      content.add({
        'type': 'input_image',
        'image_url': imageDataUrl,
      });
    }

    return {
      'model': _model,
      'instructions': _buildSystemInstructions(),
      'input': [
        {
          'role': 'user',
          'content': content,
        },
      ],
      'text': {
        'format': {
          'type': 'json_schema',
          'name': 'livestock_diagnosis_report',
          'strict': true,
          'schema': _diagnosisSchema,
        },
      },
    };
  }

  String _buildSystemInstructions() {
    return '''
Eres AgroVet AI, un asistente clínico veterinario para ganado bovino.
Analiza síntomas escritos por el usuario y, si existe, evidencia visual.
Debes entregar únicamente un JSON válido que cumpla exactamente el esquema.
No inventes hallazgos. Si la evidencia es insuficiente, indícalo claramente.
Tu salida debe ser prudente, profesional y útil para una app veterinaria.
''';
  }

  String _buildCasePrompt(DiagnosisRequest request) {
    return '''
Analiza este caso clínico de ganado y devuelve un informe estructurado.

Animal:
- Nombre: ${request.animalName}
- ID animal: ${request.animalId}
- Especie: ${request.species}
- Raza: ${request.breed ?? "No registrada"}
- Edad: ${request.ageInYears?.toString() ?? "No registrada"} años
- Peso: ${request.weight?.toString() ?? "No registrado"} kg
- Temperatura: ${request.temperature?.toString() ?? "No registrada"} °C

Motivo principal:
${request.clinicalQuestion.trim().isEmpty ? "No indicado" : request.clinicalQuestion.trim()}

Síntomas:
${request.reportedSymptoms.isEmpty ? "No indicados" : request.reportedSymptoms.join(", ")}

Hallazgos visuales reportados:
${request.visualFindings.isEmpty ? "No indicados" : request.visualFindings.join(", ")}

Notas:
- Si la imagen no es suficiente o no existe, igual debes razonar con la información textual.
- Si no hay evidencia bastante para una enfermedad concreta, devuelve un resultado preliminar prudente.
- Las acciones y tratamiento deben ser orientativos y profesionales.
''';
  }

  String? _buildImageDataUrl(Uint8List? imageBytes) {
    if (imageBytes == null || imageBytes.isEmpty) {
      return null;
    }

    final base64Image = base64Encode(imageBytes);
    return 'data:image/jpeg;base64,$base64Image';
  }

  String _extractOutputText(Map<String, dynamic> decoded) {
    final output = decoded['output'] as List<dynamic>? ?? [];

    for (final item in output) {
      final message = item as Map<String, dynamic>;
      final content = message['content'] as List<dynamic>? ?? [];

      for (final block in content) {
        final blockMap = block as Map<String, dynamic>;
        if (blockMap['type'] == 'output_text') {
          return blockMap['text'] as String? ?? '{}';
        }
      }
    }

    throw Exception(AppStrings.t('diagnosis_remote_no_output'));
  }

  List<DiagnosisFinding> _parseFindings(List<dynamic>? rawFindings) {
    if (rawFindings == null) {
      return const [];
    }

    return rawFindings.map((item) {
      final finding = item as Map<String, dynamic>;
      return DiagnosisFinding(
        label: finding['label'] as String? ?? 'Hallazgo no especificado',
        source: finding['source'] as String? ?? 'clinical',
        confidence: (finding['confidence'] as num?)?.toDouble() ?? 0.5,
        interpretation:
            finding['interpretation'] as String? ??
            'La IA identificó este hallazgo como relevante.',
      );
    }).toList();
  }

  static const Map<String, dynamic> _diagnosisSchema = {
    'type': 'object',
    'additionalProperties': false,
    'properties': {
      'primary_diagnosis': {'type': 'string'},
      'diagnostic_statement': {'type': 'string'},
      'confidence': {'type': 'number'},
      'severity_index': {'type': 'integer'},
      'urgency_index': {'type': 'integer'},
      'is_contagious': {'type': 'boolean'},
      'requires_veterinarian': {'type': 'boolean'},
      'reasoning': {'type': 'string'},
      'findings': {
        'type': 'array',
        'items': {
          'type': 'object',
          'additionalProperties': false,
          'properties': {
            'label': {'type': 'string'},
            'source': {'type': 'string'},
            'confidence': {'type': 'number'},
            'interpretation': {'type': 'string'},
          },
          'required': ['label', 'source', 'confidence', 'interpretation'],
        },
      },
      'differential_diagnoses': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'immediate_actions': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'treatment_protocol': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'isolation_measures': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'monitoring_plan': {
        'type': 'array',
        'items': {'type': 'string'},
      },
    },
    'required': [
      'primary_diagnosis',
      'diagnostic_statement',
      'confidence',
      'severity_index',
      'urgency_index',
      'is_contagious',
      'requires_veterinarian',
      'reasoning',
      'findings',
      'differential_diagnoses',
      'immediate_actions',
      'treatment_protocol',
      'isolation_measures',
      'monitoring_plan',
    ],
  };
}
