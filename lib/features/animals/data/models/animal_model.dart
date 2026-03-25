import 'package:hive/hive.dart';
import '../../domain/entities/animal_entity.dart';

part 'animal_model.g.dart';

@HiveType(typeId: 0)
class AnimalModel {
  @HiveField(0) final String id;
  @HiveField(1) final String userId;
  @HiveField(2) final String name;
  @HiveField(3) final String breed;
  @HiveField(4) final int age;
  @HiveField(5) final String symptoms;
  @HiveField(6) final DateTime createdAt;
  @HiveField(7) final DateTime updatedAt;
  @HiveField(8) final double? weight;
  @HiveField(9) final double? temperature;
  @HiveField(10) final bool isSynced;
  @HiveField(11) final String? imageUrl;
  @HiveField(12) final String? profileImageUrl;
  @HiveField(13) final String? pendingImagePath;
  @HiveField(14) final String ageLabel;

  const AnimalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.breed,
    required this.age,
    required this.symptoms,
    required this.createdAt,
    required this.updatedAt,
    required this.ageLabel,
    this.weight,
    this.temperature,
    this.imageUrl,
    this.profileImageUrl,
    this.pendingImagePath,
    this.isSynced = false,
  });

  // Convierte la Entidad a Modelo para guardar en Hive
  factory AnimalModel.fromEntity(
    AnimalEntity entity, {
    bool isSynced = false,
    String? pendingImagePath,
  }) {
    return AnimalModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name.isEmpty ? 'Sin nombre' : entity.name,
      breed: entity.breed.isEmpty ? 'Desconocida' : entity.breed,
      age: entity.age,
      ageLabel: entity.ageLabel,
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

  // Convierte el Modelo de vuelta a Entidad para la UI
  AnimalEntity toEntity() => AnimalEntity(
        id: id,
        userId: userId,
        name: name,
        breed: breed,
        age: age,
        ageLabel: ageLabel,
        symptoms: symptoms,
        createdAt: createdAt,
        updatedAt: updatedAt,
        weight: weight,
        temperature: temperature,
        imageUrl: imageUrl,
        profileImageUrl: profileImageUrl,
      );

  // Lee desde Supabase con seguridad extrema contra nulos
  factory AnimalModel.fromJson(Map<String, dynamic> json) {
    final int ageValue = (json['age'] as num?)?.toInt() ?? 0;
    
    return AnimalModel(
      id: _safeString(json['id']) ?? '',
      userId: _safeString(json['user_id']) ?? '',
      name: _safeString(json['name']) ?? 'Sin nombre',
      breed: _safeString(json['breed']) ?? 'Desconocida',
      age: ageValue,
      ageLabel: AnimalEntity.defaultAgeLabel(ageValue),
      symptoms: _safeString(json['symptoms']) ?? '',
      weight: (json['weight'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      imageUrl: _safeString(json['image_url']),
      profileImageUrl: _safeString(json['profile_image_url']),
      createdAt: _safeDateTime(json['created_at']),
      updatedAt: _safeDateTime(json['updated_at']),
      isSynced: true,
      pendingImagePath: null,
    );
  }

  // Envía a Supabase (No enviamos ageLabel porque no existe en la tabla)
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

  // Helpers de seguridad
  static String? _safeString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static DateTime _safeDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  // Sentinel para copyWith
  static const Object _sentinel = Object();

  AnimalModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? breed,
    int? age,
    String? ageLabel,
    String? symptoms,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? weight,
    double? temperature,
    Object? imageUrl = _sentinel,
    Object? profileImageUrl = _sentinel,
    Object? pendingImagePath = _sentinel,
    bool? isSynced,
  }) {
    return AnimalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      ageLabel: ageLabel ?? this.ageLabel,
      symptoms: symptoms ?? this.symptoms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      weight: weight ?? this.weight,
      temperature: temperature ?? this.temperature,
      imageUrl: imageUrl == _sentinel ? this.imageUrl : imageUrl as String?,
      profileImageUrl: profileImageUrl == _sentinel ? this.profileImageUrl : profileImageUrl as String?,
      pendingImagePath: pendingImagePath == _sentinel ? this.pendingImagePath : pendingImagePath as String?,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}