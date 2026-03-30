class AnimalEntity {
  final String id;
  final String userId;
  final String name;
  final String breed;
  final int age;
  final String ageLabel;
  final double? weight;
  final double? temperature;
  final String symptoms;
  final String? imageUrl;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnimalEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.breed,
    required this.age,
    required this.createdAt,
    required this.updatedAt,
    String? symptoms,
    String? ageLabel,
    this.weight,
    this.temperature,
    this.imageUrl,
    this.profileImageUrl,
  })  : symptoms = symptoms ?? '',
        ageLabel = ageLabel ?? '';
}
