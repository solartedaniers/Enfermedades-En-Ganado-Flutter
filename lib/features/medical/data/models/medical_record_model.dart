import '../../domain/entities/medical_record_entity.dart';
import '../../../../core/ai/models/diagnosis_response.dart';

class MedicalRecordModel extends MedicalRecordEntity {
  MedicalRecordModel({
    required super.id,
    required super.animalId,
    required super.userId,
    super.diagnosis,
    super.aiResult,
    super.imageUrl,
    required super.createdAt,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      id: json['id'],
      animalId: json['animal_id'],
      userId: json['user_id'],
      diagnosis: json['diagnosis'],
      aiResult: json['ai_result'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Convierte el reporte del motor experto al formato actual del historial.
  factory MedicalRecordModel.fromDiagnosisReport({
    required String id,
    required String animalId,
    required String userId,
    required DiagnosisReport report,
    String? imageUrl,
    String? clinicianNote,
  }) {
    return MedicalRecordModel(
      id: id,
      animalId: animalId,
      userId: userId,
      diagnosis: clinicianNote?.trim().isNotEmpty == true
          ? clinicianNote!.trim()
          : report.diagnosticStatement,
      aiResult: report.toMedicalRecordSummary(),
      imageUrl: imageUrl,
      createdAt: report.generatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animal_id': animalId,
      'user_id': userId,
      'diagnosis': diagnosis,
      'ai_result': aiResult,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
