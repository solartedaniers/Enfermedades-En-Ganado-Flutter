import 'package:hive/hive.dart';

import '../../../../core/constants/app_storage_keys.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/constants/animal_breed_catalog.dart';
import '../../domain/entities/animal_entity.dart';
import '../../shared/age_label_formatter.dart';

/// Modelo de almacenamiento local (Hive) para un animal.
/// Responsabilidad única: serialización/deserialización local con Hive.
@HiveType(typeId: 0)
class AnimalModel {
  @HiveField(AnimalHiveFields.id)
  final String id;

  @HiveField(AnimalHiveFields.userId)
  final String userId;

  @HiveField(AnimalHiveFields.name)
  final String name;

  @HiveField(AnimalHiveFields.breed)
  final String breed;

  @HiveField(AnimalHiveFields.age)
  final int age;

  @HiveField(AnimalHiveFields.symptoms)
  final String symptoms;

  @HiveField(AnimalHiveFields.createdAt)
  final DateTime createdAt;

  @HiveField(AnimalHiveFields.updatedAt)
  final DateTime updatedAt;

  @HiveField(AnimalHiveFields.weight)
  final double? weight;

  @HiveField(AnimalHiveFields.temperature)
  final double? temperature;

  @HiveField(AnimalHiveFields.isSynced)
  final bool isSynced;

  @HiveField(AnimalHiveFields.imageUrl)
  final String? imageUrl;

  @HiveField(AnimalHiveFields.profileImageUrl)
  final String? profileImageUrl;

  @HiveField(AnimalHiveFields.pendingImagePath)
  final String? pendingImagePath;

  @HiveField(AnimalHiveFields.ageLabel)
  final String ageLabel;

  @HiveField(AnimalHiveFields.isDeleted)
  final bool isDeleted;

  @HiveField(AnimalHiveFields.localProfileImagePath)
  final String? localProfileImagePath;

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
    this.localProfileImagePath,
    this.isSynced = false,
    this.isDeleted = false,
  });

  /// Crea un [AnimalModel] a partir de una entidad de dominio.
  factory AnimalModel.fromEntity(
    AnimalEntity entity, {
    bool isSynced = false,
    String? pendingImagePath,
  }) {
    return AnimalModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name.isEmpty ? AppStrings.t('animal_no_name') : entity.name,
      breed: AnimalBreedCatalog.storageValue(entity.breed),
      age: entity.age,
      ageLabel: entity.ageLabel.isNotEmpty
          ? entity.ageLabel
          : AgeLabelFormatter.format(entity.age),
      symptoms: entity.symptoms,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      weight: entity.weight,
      temperature: entity.temperature,
      imageUrl: entity.imageUrl,
      profileImageUrl: entity.profileImageUrl,
      pendingImagePath: pendingImagePath,
      localProfileImagePath: pendingImagePath ?? entity.localProfileImagePath,
      isSynced: isSynced,
      isDeleted: false,
    );
  }

  /// Convierte el modelo local a entidad de dominio.
  AnimalEntity toEntity() {
    return AnimalEntity(
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
      localProfileImagePath: localProfileImagePath,
    );
  }

  // Sentinel para permitir null explícito en copyWith
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
    Object? localProfileImagePath = _sentinel,
    bool? isSynced,
    bool? isDeleted,
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
      profileImageUrl: profileImageUrl == _sentinel
          ? this.profileImageUrl
          : profileImageUrl as String?,
      pendingImagePath: pendingImagePath == _sentinel
          ? this.pendingImagePath
          : pendingImagePath as String?,
      localProfileImagePath: localProfileImagePath == _sentinel
          ? this.localProfileImagePath
          : localProfileImagePath as String?,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
