class AnimalEntity {
  final String id;
  final String userId;
  final String name;
  final String breed;
  final int age;
  final double? weight;
  final double? temperature;
  final String symptoms;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnimalEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.breed,
    required this.age,
    required this.symptoms,
    required this.createdAt,
    required this.updatedAt,
    this.weight,
    this.temperature,
    this.imageUrl,
  });
}