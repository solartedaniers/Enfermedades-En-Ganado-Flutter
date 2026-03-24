import 'dart:typed_data';

/// Representa toda la evidencia clínica disponible para que el motor
/// pueda emitir un diagnóstico sin depender de la fuente de entrada.
class DiagnosisRequest {
  final String animalId;
  final String userId;
  final String animalName;
  final String species;
  final String? breed;
  final int? ageInYears;
  final String clinicalQuestion;
  final List<String> reportedSymptoms;
  final double? temperature;
  final double? weight;
  final Map<String, double> vitalSigns;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final List<String> visualFindings;
  final DateTime observedAt;

  const DiagnosisRequest({
    required this.animalId,
    required this.userId,
    required this.animalName,
    this.species = 'bovino',
    this.breed,
    this.ageInYears,
    this.clinicalQuestion = '',
    this.reportedSymptoms = const [],
    this.temperature,
    this.weight,
    this.vitalSigns = const {},
    this.imageBytes,
    this.imageUrl,
    this.visualFindings = const [],
    DateTime? observedAt,
  }) : observedAt = observedAt ?? DateTime.now();

  bool get hasClinicalQuestion => clinicalQuestion.trim().isNotEmpty;

  bool get hasVisualEvidence =>
      imageBytes != null ||
      (imageUrl?.trim().isNotEmpty ?? false) ||
      visualFindings.isNotEmpty;

  bool get hasSymptoms =>
      reportedSymptoms.any((item) => item.trim().isNotEmpty);

  DiagnosisRequest copyWith({
    String? animalId,
    String? userId,
    String? animalName,
    String? species,
    String? breed,
    int? ageInYears,
    String? clinicalQuestion,
    List<String>? reportedSymptoms,
    double? temperature,
    double? weight,
    Map<String, double>? vitalSigns,
    Uint8List? imageBytes,
    String? imageUrl,
    List<String>? visualFindings,
    DateTime? observedAt,
  }) {
    return DiagnosisRequest(
      animalId: animalId ?? this.animalId,
      userId: userId ?? this.userId,
      animalName: animalName ?? this.animalName,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      ageInYears: ageInYears ?? this.ageInYears,
      clinicalQuestion: clinicalQuestion ?? this.clinicalQuestion,
      reportedSymptoms: reportedSymptoms ?? this.reportedSymptoms,
      temperature: temperature ?? this.temperature,
      weight: weight ?? this.weight,
      vitalSigns: vitalSigns ?? this.vitalSigns,
      imageBytes: imageBytes ?? this.imageBytes,
      imageUrl: imageUrl ?? this.imageUrl,
      visualFindings: visualFindings ?? this.visualFindings,
      observedAt: observedAt ?? this.observedAt,
    );
  }
}
