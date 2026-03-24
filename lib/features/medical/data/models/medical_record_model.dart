import '../../domain/entities/medical_record_entity.dart';

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