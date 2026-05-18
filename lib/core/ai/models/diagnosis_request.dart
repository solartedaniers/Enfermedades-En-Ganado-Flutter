import 'dart:convert';
import 'dart:typed_data';

import '../../../geolocation/domain/entities/geolocation_context_entity.dart';
import 'livestock_detection.dart';

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
  // Imágenes adicionales (segunda, tercera, etc.) para diagnóstico multi-foto
  final List<Uint8List> additionalImages;
  final String? imageUrl;
  final List<String> visualFindings;
  final LivestockDetection? livestockDetection;
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
    this.additionalImages = const [],
    this.imageUrl,
    this.visualFindings = const [],
    this.livestockDetection,
    this.geolocationContext,
    DateTime? observedAt,
  }) : observedAt = observedAt ?? DateTime.now();

  /// Todas las imágenes del diagnóstico (principal + adicionales)
  List<Uint8List> get allImages {
    final result = <Uint8List>[];
    final primary = imageBytes;
    if (primary != null) result.add(primary);
    result.addAll(additionalImages);
    return result;
  }

  bool get hasClinicalQuestion => clinicalQuestion.trim().isNotEmpty;

  bool get hasVisualEvidence =>
      imageBytes != null ||
      additionalImages.isNotEmpty ||
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
    List<Uint8List>? additionalImages,
    String? imageUrl,
    List<String>? visualFindings,
    LivestockDetection? livestockDetection,
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
      additionalImages: additionalImages ?? this.additionalImages,
      imageUrl: imageUrl ?? this.imageUrl,
      visualFindings: visualFindings ?? this.visualFindings,
      livestockDetection: livestockDetection ?? this.livestockDetection,
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
      'image_count': allImages.length,
      'image_url': imageUrl,
      'visual_findings': visualFindings,
      'livestock_detection': livestockDetection?.toJson(),
      'validated_species': livestockDetection?.species ?? species,
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
