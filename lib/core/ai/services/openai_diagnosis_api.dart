import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../utils/app_strings.dart';
import '../models/diagnosis_request.dart';
import '../models/diagnosis_response.dart';

class OpenAIDiagnosisApi {
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String _model = String.fromEnvironment(
    'OPENAI_DIAGNOSIS_MODEL',
    defaultValue: 'gpt-4.1',
  );

  const OpenAIDiagnosisApi();

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<DiagnosisReport> createDiagnosisReport(
    DiagnosisRequest request,
  ) async {
    if (!isConfigured) {
      throw Exception(AppStrings.t('diagnosis_openai_missing_key'));
    }

    final httpClient = HttpClient();

    try {
      final httpRequest = await httpClient.postUrl(
        Uri.parse('https://api.openai.com/v1/responses'),
      );

      httpRequest.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $_apiKey',
      );
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
        throw Exception(
          _buildFriendlyError(httpResponse.statusCode, responseBody),
        );
      }

      final decodedBody = jsonDecode(responseBody) as Map<String, dynamic>;
      final outputText = _extractOutputText(decodedBody);
      final reportJson = jsonDecode(outputText) as Map<String, dynamic>;

      return DiagnosisReport(
        primaryDiagnosis:
            reportJson['primary_diagnosis'] as String? ?? 'undetermined',
        diagnosticStatement:
            reportJson['diagnostic_statement'] as String? ??
            AppStrings.t('diagnosis_default_statement'),
        confidence: (reportJson['confidence'] as num?)?.toDouble() ?? 0.0,
        severityIndex: (reportJson['severity_index'] as num?)?.toInt() ?? 20,
        urgencyIndex: (reportJson['urgency_index'] as num?)?.toInt() ?? 25,
        isContagious: reportJson['is_contagious'] as bool? ?? false,
        requiresVeterinarian:
            reportJson['requires_veterinarian'] as bool? ?? false,
        reasoning:
            reportJson['reasoning'] as String? ??
            AppStrings.t('diagnosis_default_reasoning'),
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
      throw Exception(AppStrings.t('diagnosis_openai_connection_error'));
    } on FormatException {
      throw Exception(AppStrings.t('diagnosis_openai_invalid_response'));
    } finally {
      httpClient.close();
    }
  }

  String _buildFriendlyError(int statusCode, String responseBody) {
    try {
      final decodedBody = jsonDecode(responseBody) as Map<String, dynamic>;
      final error = decodedBody['error'] as Map<String, dynamic>?;
      final code = error?['code']?.toString();
      final message = error?['message']?.toString();

      if (statusCode == 401 || code == 'invalid_api_key') {
        return AppStrings.t('diagnosis_openai_invalid_key');
      }

      if (statusCode == 429) {
        return AppStrings.t('diagnosis_openai_rate_limit');
      }

      if (statusCode >= 500) {
        return AppStrings.t('diagnosis_openai_server_error');
      }

      return message ?? 'OpenAI error $statusCode';
    } catch (_) {
      return 'OpenAI error $statusCode';
    }
  }

  Map<String, dynamic> _buildPayload(DiagnosisRequest request) {
    final inputContent = <Map<String, dynamic>>[
      {
        'type': 'input_text',
        'text': _buildCasePrompt(request),
      },
    ];

    final imageDataUrl = _buildImageDataUrl(request.imageBytes);
    if (imageDataUrl != null) {
      inputContent.add({
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
          'content': inputContent,
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
    final language = AppStrings.currentLanguage == 'en' ? 'English' : 'Spanish';

    return '''
You are AgroVet AI, a veterinary clinical assistant for cattle.
Analyze written symptoms and optional visual evidence.
Return only valid JSON that matches the schema exactly.
Do not invent findings. If the evidence is insufficient, state that clearly.
Write the final clinical content in $language.
''';
  }

  String _buildCasePrompt(DiagnosisRequest request) {
    return '''
Analyze this livestock clinical case and return a structured report.

Animal:
- Name: ${request.animalName}
- Animal ID: ${request.animalId}
- Species: ${request.species}
- Breed: ${request.breed ?? "Not recorded"}
- Age: ${request.ageInYears?.toString() ?? "Not recorded"} years
- Weight: ${request.weight?.toString() ?? "Not recorded"} kg
- Temperature: ${request.temperature?.toString() ?? "Not recorded"} °C

Main concern:
${request.clinicalQuestion.trim().isEmpty ? "Not provided" : request.clinicalQuestion.trim()}

Reported symptoms:
${request.reportedSymptoms.isEmpty ? "Not provided" : request.reportedSymptoms.join(", ")}

Reported visual findings:
${request.visualFindings.isEmpty ? "Not provided" : request.visualFindings.join(", ")}

Notes:
- If the image is missing or insufficient, still reason from the text evidence.
- If there is not enough evidence for a specific disease, return a prudent preliminary result.
- Actions and treatment must stay orientative and professional.
''';
  }

  String? _buildImageDataUrl(Uint8List? imageBytes) {
    if (imageBytes == null || imageBytes.isEmpty) {
      return null;
    }

    final base64Image = base64Encode(imageBytes);
    return 'data:image/jpeg;base64,$base64Image';
  }

  String _extractOutputText(Map<String, dynamic> decodedBody) {
    final outputItems = decodedBody['output'] as List<dynamic>? ?? [];

    for (final outputItem in outputItems) {
      final messageBlock = outputItem as Map<String, dynamic>;
      final contentBlocks = messageBlock['content'] as List<dynamic>? ?? [];

      for (final contentBlock in contentBlocks) {
        final blockMap = contentBlock as Map<String, dynamic>;
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
        label: finding['label'] as String? ??
            AppStrings.t('diagnosis_finding_unspecified'),
        source: finding['source'] as String? ?? 'clinical',
        confidence: (finding['confidence'] as num?)?.toDouble() ?? 0.5,
        interpretation:
            finding['interpretation'] as String? ??
            AppStrings.t('diagnosis_default_finding_interpretation'),
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
