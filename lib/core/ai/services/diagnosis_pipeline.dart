import 'dart:typed_data';

import 'groq_diagnosis_api.dart';
import 'image_preprocessing_service.dart';
import '../models/diagnosis_request.dart';
import '../models/diagnosis_response.dart';

/// Pipeline de diagnóstico simplificado para uso fuera del flujo principal.
/// Para el flujo completo de la app, usar LivestockDiagnosisService.
class DiagnosisPipeline {
  final GroqDiagnosisApi _groqApi = const GroqDiagnosisApi();
  final ImagePreprocessingService _imageService =
      const ImagePreprocessingService();

  const DiagnosisPipeline();

  Future<DiagnosisReport> runPipeline({
    required Uint8List imageBytes,
    required String animalName,
    String species = 'bovine',
    String clinicalQuestion = '',
    List<String> reportedSymptoms = const [],
    // IDs opcionales — necesarios si se quiere guardar el resultado en Supabase
    String animalId = '',
    String userId = '',
  }) async {
    // Preprocesar imagen: ajustar tamaño, contraste y brillo
    final processedImage = await _imageService.preprocessImage(imageBytes);

    // Extraer metadatos visuales para enriquecer el contexto del prompt
    final visualMetadata =
        await _imageService.extractVisualMetadata(processedImage);
    final visualFindings = _buildVisualFindings(visualMetadata);

    final request = DiagnosisRequest(
      animalId: animalId,
      userId: userId,
      animalName: animalName,
      species: species,
      clinicalQuestion: clinicalQuestion,
      reportedSymptoms: reportedSymptoms,
      visualFindings: visualFindings,
      imageBytes: processedImage,
    );

    return _groqApi.createDiagnosisReport(request);
  }

  List<String> _buildVisualFindings(Map<String, dynamic> metadata) {
    if (metadata.isEmpty) return [];

    final findings = <String>[];
    final avgLuminance = metadata['average_luminance'] as double? ?? 0;
    final aspectRatio = metadata['aspect_ratio'] as double? ?? 1;

    if (avgLuminance > 200) {
      findings.add('Imagen sobreexpuesta — áreas claras dominantes');
    } else if (avgLuminance < 50) {
      findings.add('Imagen subexpuesta — áreas oscuras dominantes');
    }

    if (aspectRatio > 2.0) {
      findings.add('Composición panorámica — posible vista lateral amplia');
    } else if (aspectRatio < 0.5) {
      findings.add('Composición vertical — posible vista frontal o posterior');
    }

    return findings;
  }
}
