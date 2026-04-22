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
  final String? localProfileImagePath;
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
    this.localProfileImagePath,
  })  : symptoms = symptoms ?? '',
        ageLabel = ageLabel ?? '';

  AnimalEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? breed,
    int? age,
    String? ageLabel,
    double? weight,
    bool clearWeight = false,
    double? temperature,
    bool clearTemperature = false,
    String? symptoms,
    String? imageUrl,
    bool clearImageUrl = false,
    String? profileImageUrl,
    bool clearProfileImageUrl = false,
    String? localProfileImagePath,
    bool clearLocalProfileImagePath = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnimalEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      ageLabel: ageLabel ?? this.ageLabel,
      symptoms: symptoms ?? this.symptoms,
      weight: clearWeight ? null : (weight ?? this.weight),
      temperature:
          clearTemperature ? null : (temperature ?? this.temperature),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      profileImageUrl: clearProfileImageUrl
          ? null
          : (profileImageUrl ?? this.profileImageUrl),
      localProfileImagePath: clearLocalProfileImagePath
          ? null
          : (localProfileImagePath ?? this.localProfileImagePath),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
