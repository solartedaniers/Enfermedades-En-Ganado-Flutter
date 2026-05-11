import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;

import '../models/diagnosis_request.dart';
import '../models/diagnosis_response.dart';

class GroqDiagnosisApi {
  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  // Modelo de texto puro: genera JSON de forma muy confiable
  static const String _textModel = 'llama-3.3-70b-versatile';
  // Modelo de visión: analiza la imagen real del animal
  static const String _visionModel = 'llama-3.2-11b-vision-preview';
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // Máximo de píxeles al lado más largo para el payload de visión
  static const int _visionMaxDimension = 512;

  const GroqDiagnosisApi();

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<DiagnosisReport> createDiagnosisReport(
    DiagnosisRequest request,
  ) async {
    if (!isConfigured) {
      throw Exception('GROQ_API_KEY no configurada en el archivo .env');
    }

    final imageBytes = request.imageBytes;
    final hasImage = imageBytes != null && imageBytes.isNotEmpty;

    final client = HttpClient();
    try {
      final httpRequest = await client.postUrl(Uri.parse(_baseUrl));
      httpRequest.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $_apiKey',
      );
      httpRequest.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );

      // Si hay imagen: usamos modelo de visión y enviamos la foto como base64
      final payload =
          hasImage
              ? _buildVisionPayload(request, imageBytes)
              : _buildTextPayload(request);

      httpRequest.add(utf8.encode(jsonEncode(payload)));

      final httpResponse = await httpRequest.close();
      final responseBody = await utf8.decodeStream(httpResponse);

      if (httpResponse.statusCode >= 400) {
        throw Exception(
          'Error Groq (${httpResponse.statusCode}): $responseBody',
        );
      }

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final content =
          decoded['choices'][0]['message']['content'] as String;

      final cleanJson = _extractJson(content);
      final reportJson = jsonDecode(cleanJson) as Map<String, dynamic>;

      return _buildReport(reportJson, request);
    } on SocketException {
      throw Exception('Sin conexión a internet para el diagnóstico.');
    } catch (e, stackTrace) {
      developer.log(
        'Error procesando respuesta de Groq',
        name: 'GroqDiagnosisApi',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Error al procesar diagnóstico: $e');
    } finally {
      client.close();
    }
  }

  // Payload para análisis solo con texto/síntomas (sin imagen)
  Map<String, dynamic> _buildTextPayload(DiagnosisRequest request) {
    return {
      'model': _textModel,
      'messages': [
        {'role': 'system', 'content': _buildSystemPrompt()},
        {'role': 'user', 'content': _buildCasePrompt(request)},
      ],
      'temperature': 0.15,
      'max_tokens': 2048,
      // response_format json_object es muy confiable en modelos de texto
      'response_format': {'type': 'json_object'},
    };
  }

  // Payload para análisis visual: envía la foto real al modelo de visión
  Map<String, dynamic> _buildVisionPayload(
    DiagnosisRequest request,
    Uint8List imageBytes,
  ) {
    // Reducir imagen a 512px para minimizar el payload y cumplir límites de la API
    final visionBytes = _resizeForVision(imageBytes);
    final base64Image = base64Encode(visionBytes);

    return {
      'model': _visionModel,
      'messages': [
        // El modelo de visión acepta system prompt como rol separado
        {'role': 'system', 'content': _buildSystemPrompt()},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': _buildCasePrompt(request)},
            {
              // Enviamos la imagen como data URI base64
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
              },
            },
          ],
        },
      ],
      'temperature': 0.15,
      'max_tokens': 2048,
    };
  }

  // Redimensiona y re-codifica la imagen para optimizar el payload de visión
  Uint8List _resizeForVision(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      if (image.width <= _visionMaxDimension &&
          image.height <= _visionMaxDimension) {
        return Uint8List.fromList(img.encodeJpg(image, quality: 80));
      }

      final larger =
          image.width > image.height ? image.width : image.height;
      final scale = _visionMaxDimension / larger;
      final resized = img.copyResize(
        image,
        width: (image.width * scale).toInt(),
        height: (image.height * scale).toInt(),
        interpolation: img.Interpolation.linear,
      );
      return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
    } catch (_) {
      // Si falla el resize, enviar bytes originales (mejor que fallar el diagnóstico)
      return bytes;
    }
  }

  // Extrae el bloque JSON de la respuesta del modelo, ignorando posibles
  // envolturas de markdown (``` json ... ```) que algunos modelos agregan
  String _extractJson(String text) {
    var cleaned =
        text
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '')
            .trim();

    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return cleaned.substring(start, end + 1);
    }
    return cleaned;
  }

  String _buildSystemPrompt() {
    return '''Eres AgroVet AI, un asistente de diagnóstico veterinario para ganado bovino, porcino, equino, ovino y caprino.

⚠️ AVISO CRÍTICO: Esta herramienta es una AYUDA basada en IA y NO reemplaza al veterinario. Los resultados NO son 100% confiables. Siempre recomienda consulta con un Médico Veterinario colegiado.

PRINCIPIOS DE ANÁLISIS:
1. Usa SIEMPRE lenguaje probabilístico: "Compatible con...", "Sugiere...", "Probabilidad del X%..."
2. NUNCA asumas diagnósticos absolutos — siempre "presuntivo" y "sugestivo"
3. Si se proporciona imagen: analiza coloración, textura, lesiones, inflamación, asimetría, postura, condición corporal, ojos, mucosas, piel
4. Correlaciona hallazgos visuales con los síntomas reportados
5. Traduce los síntomas del usuario a terminología veterinaria profesional

DETECCIÓN DE INCONSISTENCIAS:
Si la combinación especie-síntoma es biológicamente implausible, establece en "diagnostic_statement":
"Se detectó una inconsistencia en la información proporcionada. Verifique que la especie y síntomas sean compatibles."

SALIDA OBLIGATORIA: Responde ÚNICAMENTE con este JSON exacto, sin texto adicional:
{
  "primary_diagnosis": "nombre_enfermedad",
  "diagnostic_statement": "Con base en la evidencia, los patrones son compatibles con... con una probabilidad del X%...",
  "confidence": 0.75,
  "severity_index": 65,
  "urgency_index": 60,
  "is_contagious": true,
  "requires_veterinarian": true,
  "reasoning": "Correlación detallada de hallazgos visuales y clínicos",
  "symptom_analysis": "Síntomas en terminología veterinaria",
  "visual_findings": "Descripción de patrones visuales observados en la imagen",
  "validated_species": "especie_registrada",
  "visual_detection_confidence": 0.82,
  "findings": [{"label": "hallazgo", "source": "visual", "confidence": 0.85, "interpretation": "significado"}],
  "differential_diagnoses": ["opcion1 (70%)", "opcion2 (20%)", "opcion3 (10%)"],
  "preventive_suggestions": ["medida_preventiva_1", "medida_preventiva_2"],
  "immediate_actions": ["accion_inmediata_1", "accion_inmediata_2"],
  "monitoring_plan": ["monitoreo_1", "monitoreo_2"],
  "disclaimer": "⚠️ Este análisis es una asistencia basada en IA y NO es 100% confiable. NO sustituye la evaluación presencial de un Médico Veterinario colegiado. No tome decisiones de tratamiento basándose únicamente en este resultado."
}

GUÍAS POR CAMPO:
- visual_findings: Solo si hay imagen — describe color, textura, lesiones, inflamación, asimetría, postura
- findings: Máximo 5 hallazgos clave con fuente (visual/clinical/reported) y confianza
- differential_diagnoses: Ordenados por probabilidad con % explícito (ej: "Sarna (65%)")
- confidence: 0.40-0.95 según robustez de la evidencia
- severity_index: 0-100 (0=ninguno, 100=crítico)
- urgency_index: 0-100 (0=puede esperar, 100=emergencia inmediata)
''';
  }

  String _buildCasePrompt(DiagnosisRequest request) {
    final lines = <String>[];

    lines.add('ANÁLISIS DE CASO CLÍNICO:\n');

    // --- Información del animal ---
    lines.add('INFORMACIÓN DEL ANIMAL:');
    lines.add('• Nombre: ${request.animalName}');
    lines.add('• Especie: ${request.species}');
    if (request.breed?.trim().isNotEmpty == true) {
      lines.add('• Raza: ${request.breed}');
    }
    if (request.ageInYears != null) {
      lines.add('• Edad: aproximadamente ${request.ageInYears} meses');
    }
    if (request.weight != null) {
      lines.add('• Peso: ${request.weight} kg');
    }
    if (request.temperature != null) {
      lines.add('• Temperatura corporal: ${request.temperature}°C');
    }

    // --- Contexto geográfico (ayuda con enfermedades endémicas) ---
    final geo = request.geolocationContext;
    if (geo != null) {
      // Tomar el primer campo de ubicación disponible (locality > area > country)
      final location = [geo.locality, geo.administrativeArea, geo.country]
          .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');
      if (location.isNotEmpty) lines.add('• Ubicación: $location');
      if (geo.climateZone.trim().isNotEmpty) {
        lines.add('• Zona climática: ${geo.climateZone}');
      }
      if (geo.epidemiologySummary.trim().isNotEmpty) {
        lines.add('• Epidemiología regional: ${geo.epidemiologySummary}');
      }
    }

    // --- Pregunta clínica del usuario ---
    if (request.clinicalQuestion.trim().isNotEmpty) {
      lines.add('\nPREGUNTA CLÍNICA:');
      lines.add('"${request.clinicalQuestion.trim()}"');
    }

    // --- Síntomas reportados ---
    if (request.reportedSymptoms.isNotEmpty) {
      lines.add('\nSÍNTOMAS REPORTADOS:');
      for (final symptom in request.reportedSymptoms) {
        lines.add('• $symptom');
      }
    } else {
      lines.add('\nSÍNTOMAS: No se especificaron síntomas adicionales');
    }

    // --- Hallazgos visuales previos del preprocesamiento ---
    if (request.visualFindings.isNotEmpty) {
      lines.add('\nHALLAZGOS PREVIOS (análisis local):');
      for (final finding in request.visualFindings) {
        lines.add('• $finding');
      }
    }

    // --- Estado de la imagen ---
    if (request.imageBytes != null) {
      lines.add(
        '\nIMAGEN ADJUNTA: SÍ — analiza cuidadosamente la imagen para '
        'detectar lesiones, cambios de coloración, signos de dolor o malestar.',
      );
    } else {
      lines.add(
        '\nIMAGEN ADJUNTA: NO — basa el análisis únicamente en síntomas '
        'y la pregunta clínica.',
      );
    }

    lines.add('\nINSTRUCCIONES:');
    lines.add(
      '1. Analiza toda la evidencia disponible '
      '(imagen si hay, síntomas, pregunta clínica)',
    );
    lines.add('2. Expresa probabilidades de forma explícita y numérica');
    lines.add('3. Provee diagnósticos diferenciales ordenados por probabilidad');
    lines.add(
      '4. Incluye el disclaimer indicando que esto NO es 100% confiable',
    );
    lines.add('5. Responde ÚNICAMENTE con el JSON estructurado definido');

    return lines.join('\n');
  }

  DiagnosisReport _buildReport(
    Map<String, dynamic> json,
    DiagnosisRequest request,
  ) {
    return DiagnosisReport(
      primaryDiagnosis:
          json['primary_diagnosis'] as String? ?? 'Indeterminado',
      diagnosticStatement:
          json['diagnostic_statement'] as String? ??
          'No se pudo generar un análisis diagnóstico.',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      severityIndex: (json['severity_index'] as num?)?.toInt() ?? 0,
      urgencyIndex: (json['urgency_index'] as num?)?.toInt() ?? 0,
      isContagious: json['is_contagious'] as bool? ?? false,
      requiresVeterinarian: json['requires_veterinarian'] as bool? ?? true,
      reasoning: json['reasoning'] as String? ?? '',
      symptomAnalysis: json['symptom_analysis'] as String? ?? '',
      validatedSpecies:
          json['validated_species'] as String? ?? request.species,
      visualDetectionConfidence:
          (json['visual_detection_confidence'] as num?)?.toDouble(),
      disclaimer:
          json['disclaimer'] as String? ??
          '⚠️ Este análisis es una asistencia basada en IA y NO es 100% '
              'confiable. NO sustituye la evaluación presencial de un Médico '
              'Veterinario colegiado.',
      findings: _parseFindings(json['findings']),
      differentialDiagnoses: List<String>.from(
        json['differential_diagnoses'] ?? [],
      ),
      immediateActions: List<String>.from(json['immediate_actions'] ?? []),
      treatmentProtocol: List<String>.from(
        // El modelo puede llamarlo preventive_suggestions o treatment_protocol
        json['preventive_suggestions'] ?? json['treatment_protocol'] ?? [],
      ),
      isolationMeasures: List<String>.from(
        json['isolation_measures'] ?? [],
      ),
      monitoringPlan: List<String>.from(json['monitoring_plan'] ?? []),
    );
  }

  List<DiagnosisFinding> _parseFindings(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => DiagnosisFinding(
            label: item['label'] as String? ?? '',
            source: item['source'] as String? ?? 'clinical',
            confidence: (item['confidence'] as num?)?.toDouble() ?? 0.0,
            interpretation: item['interpretation'] as String? ?? '',
          ),
        )
        .toList();
  }
}
