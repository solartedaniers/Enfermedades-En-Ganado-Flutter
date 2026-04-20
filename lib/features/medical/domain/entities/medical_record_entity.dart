class MedicalRecordEntity {
  final String id;
  final String animalId;
  final String userId;
  final String? diagnosis;
  final String? aiResult;
  final String? imageUrl;
  final DateTime createdAt;

  MedicalRecordEntity({
    required this.id,
    required this.animalId,
    required this.userId,
    this.diagnosis,
    this.aiResult,
    this.imageUrl,
    required this.createdAt,
  });
}
