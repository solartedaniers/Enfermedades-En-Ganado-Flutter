import 'package:hive/hive.dart';
import '../../domain/entities/animal_entity.dart';

part 'animal_model.g.dart';

@HiveType(typeId: 0)
class AnimalModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String breed;

  @HiveField(4)
  final int age;

  @HiveField(5)
  final String symptoms;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final double? weight;

  @HiveField(9)
  final double? temperature;

  @HiveField(10)
  final bool isSynced;

  @HiveField(11)
  final String? imageUrl;

  @HiveField(12)
  final String? profileImageUrl;

  @HiveField(13)
  final String? pendingImagePath; // ruta local cuando no hay internet

  const AnimalModel({
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
    this.profileImageUrl,
    this.pendingImagePath,
    this.isSynced = false,
  });

  AnimalModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? breed,
    int? age,
    String? symptoms,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? weight,
    double? temperature,
    String? imageUrl,
    String? profileImageUrl,
    String? pendingImagePath,
    bool? isSynced,
  }) {
    return AnimalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      symptoms: symptoms ?? this.symptoms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      weight: weight ?? this.weight,
      temperature: temperature ?? this.temperature,
      imageUrl: imageUrl ?? this.imageUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      pendingImagePath: pendingImagePath ?? this.pendingImagePath,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  AnimalEntity toEntity() => AnimalEntity(
        id: id,
        userId: userId,
        name: name,
        breed: breed,
        age: age,
        symptoms: symptoms,
        createdAt: createdAt,
        updatedAt: updatedAt,
        weight: weight,
        temperature: temperature,
        imageUrl: imageUrl,
        profileImageUrl: profileImageUrl,
      );

  factory AnimalModel.fromEntity(AnimalEntity entity,
      {bool isSynced = false, String? pendingImagePath}) {
    return AnimalModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      breed: entity.breed,
      age: entity.age,
      symptoms: entity.symptoms,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      weight: entity.weight,
      temperature: entity.temperature,
      imageUrl: entity.imageUrl,
      profileImageUrl: entity.profileImageUrl,
      pendingImagePath: pendingImagePath,
      isSynced: isSynced,
    );
  }

  factory AnimalModel.fromJson(Map<String, dynamic> json) {
    return AnimalModel(
      id: json['id'],
      userId: json['user_id'] ?? '',
      name: json['name'],
      breed: json['breed'],
      age: json['age'],
      symptoms: json['symptoms'],
      weight: (json['weight'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      imageUrl: json['image_url'],
      profileImageUrl: json['profile_image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isSynced: true,
      pendingImagePath: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'breed': breed,
      'age': age,
      'symptoms': symptoms,
      'weight': weight,
      'temperature': temperature,
      'image_url': imageUrl,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}