import 'dart:convert';
import 'dart:typed_data';

import '../../../geolocation/domain/entities/geolocation_context_entity.dart';

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
  final GeolocationContextEntity? geolocationContext;
  final DateTime observedAt;

  DiagnosisRequest({
    required this.animalId,
    required this.userId,
    required this.animalName,
    this.species = 'bovine',
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
    this.geolocationContext,
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
    GeolocationContextEntity? geolocationContext,
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
      geolocationContext: geolocationContext ?? this.geolocationContext,
      observedAt: observedAt ?? this.observedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animal_id': animalId,
      'user_id': userId,
      'animal_name': animalName,
      'species': species,
      'breed': breed,
      'age_in_years': ageInYears,
      'clinical_question': clinicalQuestion,
      'reported_symptoms': reportedSymptoms,
      'temperature': temperature,
      'weight': weight,
      'vital_signs': vitalSigns,
      'image_base64': imageBytes == null ? null : base64Encode(imageBytes!),
      'image_url': imageUrl,
      'visual_findings': visualFindings,
      'geolocation_context': geolocationContext == null
          ? null
          : {
              'latitude': geolocationContext!.latitude,
              'longitude': geolocationContext!.longitude,
              'country': geolocationContext!.country,
              'country_code': geolocationContext!.countryCode,
              'administrative_area': geolocationContext!.administrativeArea,
              'locality': geolocationContext!.locality,
              'climate_zone': geolocationContext!.climateZone,
              'epidemiology_summary': geolocationContext!.epidemiologySummary,
              'common_disease_keys': geolocationContext!.commonDiseaseKeys,
            },
      'observed_at': observedAt.toIso8601String(),
    };
  }
}
