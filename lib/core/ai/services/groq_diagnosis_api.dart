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
  // Modelo de visión: Llama 4 Scout soporta imagen + texto en Groq
  static const String _visionModel =
      'meta-llama/llama-4-scout-17b-16e-instruct';
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

    final allImages = request.allImages;
    final hasImages = allImages.isNotEmpty;

    // Con imágenes → modelo de visión; fallback a texto si falla
    if (hasImages) {
      try {
        return await _callGroq(
          _buildVisionPayload(request, allImages),
          request,
        );
      } catch (e) {
        developer.log(
          'Modelo de visión no disponible, reintentando sin imagen',
          name: 'GroqDiagnosisApi',
          error: e,
        );
        final textRequest = request.copyWith(imageBytes: null, additionalImages: []);
        return await _callGroq(_buildTextPayload(textRequest), textRequest);
      }
    }

    return await _callGroq(_buildTextPayload(request), request);
  }

  Future<DiagnosisReport> _callGroq(
    Map<String, dynamic> payload,
    DiagnosisRequest request,
  ) async {
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

  // Payload para análisis visual: envía todas las imágenes al modelo de visión
  Map<String, dynamic> _buildVisionPayload(
    DiagnosisRequest request,
    List<Uint8List> images,
  ) {
    // Construir el array de contenido: texto + una entrada por imagen (máx 4)
    final contentItems = <Map<String, dynamic>>[
      {'type': 'text', 'text': _buildCasePrompt(request)},
    ];

    for (final imageBytes in images.take(4)) {
      final visionBytes = _resizeForVision(imageBytes);
      contentItems.add({
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,${base64Encode(visionBytes)}'},
      });
    }

    return {
      'model': _visionModel,
      'messages': [
        {'role': 'system', 'content': _buildSystemPrompt()},
        {'role': 'user', 'content': contentItems},
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
    return '''Eres AgroVet AI, un asistente veterinario especializado en diagnóstico de ganado bovino, porcino, equino, ovino y caprino.

⚠️ AVISO IMPORTANTE: Esta herramienta es una AYUDA basada en IA y NO reemplaza al veterinario. Los resultados NO son 100% confiables. Siempre recomienda consulta con un Médico Veterinario colegiado.

INTERPRETACIÓN DE LENGUAJE DEL GANADERO:
Los usuarios son campesinos y ganaderos que describen síntomas en lenguaje cotidiano. NUNCA rechaces una descripción por ser coloquial. Interpreta y traduce:
- "le salieron manchas" → lesiones dérmicas, posible dermatopatía
- "se ve raro" → alteración del comportamiento o condición corporal
- "no quiere comer" → anorexia, inapetencia
- "está caído" → postración, decaimiento, debilidad general
- "tiene los ojos raros" → signos oculares: secreción, opacidad, enrojecimiento
- "le sale moco" → secreción nasal, rinorrea
- "está flaco" → pérdida de condición corporal, caquexia
- "le salen costras" → dermatitis con formación de costras, sarna, tiña
- "está hinchado" → edema, inflamación local o sistémica
- "tiene puntos blancos" → posibles nódulos, vesículas, pústulas

PRINCIPIOS DE ANÁLISIS:
1. Usa lenguaje probabilístico: "Compatible con...", "Sugiere...", "Probabilidad del X%..."
2. NUNCA asumas diagnóstico absoluto — siempre presuntivo
3. Si hay imagen: analiza minuciosamente coloración, textura, distribución de lesiones, estado de pelo/piel, postura, condición corporal, ojos, mucosas
4. Correlaciona hallazgos visuales con síntomas reportados
5. Responde SIEMPRE en español
6. Traduce el lenguaje coloquial a terminología veterinaria en "symptom_analysis"

ENTRADA SIN RELEVANCIA VETERINARIA:
Si el texto no describe ningún síntoma, comportamiento, condición física o problema de salud de un animal (ejemplo: "futbol", "hola", "abc", nombres de lugares sin contexto clínico), responde así:
- primary_diagnosis: "Información insuficiente"
- diagnostic_statement: "No se identificaron síntomas veterinarios en la descripción. Por favor describe qué le pasa al animal: si tiene fiebre, manchas, no come, cojea, está decaído, etc."
- confidence: 0.0
- severity_index: 0
- urgency_index: 0
- requires_veterinarian: false
- findings: []
- differential_diagnoses: []
- immediate_actions: ["Describe los síntomas reales del animal para obtener un diagnóstico"]
- monitoring_plan: []

INCONSISTENCIA REAL: Solo marca inconsistencia si la especie es biológicamente imposible para el síntoma (ej: bovino con síntomas exclusivos de reptiles). NO marques inconsistencia por descripción coloquial o imprecisa.

SALIDA OBLIGATORIA: Responde ÚNICAMENTE con este JSON exacto, sin texto adicional:
{
  "primary_diagnosis": "Nombre de la enfermedad o condición presuntiva",
  "diagnostic_statement": "Con base en la evidencia, los patrones observados son compatibles con [diagnóstico] con una probabilidad estimada del X%. [Descripción clínica de los hallazgos principales]",
  "confidence": 0.75,
  "severity_index": 65,
  "urgency_index": 60,
  "is_contagious": true,
  "requires_veterinarian": true,
  "reasoning": "Correlación detallada entre hallazgos visuales, síntomas reportados y fisiopatología de la enfermedad presuntiva",
  "symptom_analysis": "Traducción clínica: los síntomas descritos como [lenguaje usuario] corresponden a [terminología veterinaria]. Análisis: [interpretación]",
  "visual_findings": "Hallazgos visuales: [descripción detallada de lo observado en la imagen — color, distribución, forma, tamaño de lesiones]",
  "validated_species": "bovine",
  "visual_detection_confidence": 0.82,
  "findings": [{"label": "hallazgo específico", "source": "visual", "confidence": 0.85, "interpretation": "significado clínico del hallazgo"}],
  "differential_diagnoses": ["Diagnóstico 1 (70%) - razón", "Diagnóstico 2 (20%) - razón", "Diagnóstico 3 (10%) - razón"],
  "preventive_suggestions": ["Medida preventiva específica 1", "Medida preventiva específica 2", "Medida preventiva específica 3"],
  "immediate_actions": ["Acción inmediata 1", "Acción inmediata 2", "Acción inmediata 3"],
  "monitoring_plan": ["Parámetro a monitorear 1 cada X horas/días", "Parámetro a monitorear 2"],
  "disclaimer": "⚠️ Este análisis es una asistencia basada en IA y NO es 100% confiable. NO sustituye la evaluación presencial de un Médico Veterinario colegiado. No tome decisiones de tratamiento basándose únicamente en este resultado."
}

GUÍAS DE CALIDAD:
- diagnostic_statement: Mínimo 2 oraciones; incluye % de probabilidad y descripción de hallazgos
- reasoning: Mínimo 3 oraciones; explica POR QUÉ ese diagnóstico y no otro
- symptom_analysis: SIEMPRE incluir; traduce lenguaje coloquial a veterinario y explica su significado clínico
- visual_findings: Si hay imagen, describir en detalle; si no, indicar "Sin imagen adjunta — análisis basado en síntomas reportados"
- findings: Mínimo 3, máximo 6 hallazgos concretos y específicos
- differential_diagnoses: Exactamente 3 opciones, ordenadas por probabilidad con % y razón breve
- preventive_suggestions: Mínimo 3 medidas concretas y aplicables
- immediate_actions: Mínimo 2 acciones urgentes y prácticas para el ganadero
- confidence: 0.40-0.95
- severity_index: 0-100 (0=sin riesgo, 100=crítico)
- urgency_index: 0-100 (0=puede esperar, 100=emergencia)
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
