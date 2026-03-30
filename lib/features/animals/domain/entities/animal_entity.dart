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
        ageLabel = ageLabel ?? defaultAgeLabel(age);

  static String defaultAgeLabel(int months) {
    if (months < 1) return 'Recién nacido';
    if (months < 12) {
      return months == 1 ? '1 mes' : '$months meses';
    }
    final years = months ~/ 12;
    return years == 1 ? '1 año' : '$years años';
  }
}