import 'package:hive/hive.dart';

import '../../../../core/constants/app_storage_keys.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/animal_entity.dart';
import '../../shared/age_label_formatter.dart';

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

  factory AnimalModel.fromEntity(
    AnimalEntity entity, {
    bool isSynced = false,
    String? pendingImagePath,
  }) {
    return AnimalModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name.isEmpty ? AppStrings.t('animal_no_name') : entity.name,
      breed: entity.breed.isEmpty
          ? AppStrings.t('animal_unknown_breed')
          : entity.breed,
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
      isSynced: isSynced,
    );
  }

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
    );
  }

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
      profileImageUrl: profileImageUrl == _sentinel
          ? this.profileImageUrl
          : profileImageUrl as String?,
      pendingImagePath: pendingImagePath == _sentinel
          ? this.pendingImagePath
          : pendingImagePath as String?,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

class AnimalModelAdapter extends TypeAdapter<AnimalModel> {
  @override
  final int typeId = 0;

  @override
  AnimalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final age = (fields[AnimalHiveFields.age] as int?) ?? 0;

    return AnimalModel(
      id: (fields[AnimalHiveFields.id] as String?) ?? '',
      userId: (fields[AnimalHiveFields.userId] as String?) ?? '',
      name: (fields[AnimalHiveFields.name] as String?) ??
          AppStrings.t('animal_no_name'),
      breed: (fields[AnimalHiveFields.breed] as String?) ??
          AppStrings.t('animal_unknown_breed'),
      age: age,
      symptoms: (fields[AnimalHiveFields.symptoms] as String?) ?? '',
      createdAt:
          (fields[AnimalHiveFields.createdAt] as DateTime?) ?? DateTime.now(),
      updatedAt:
          (fields[AnimalHiveFields.updatedAt] as DateTime?) ?? DateTime.now(),
      weight: fields[AnimalHiveFields.weight] as double?,
      temperature: fields[AnimalHiveFields.temperature] as double?,
      isSynced: (fields[AnimalHiveFields.isSynced] as bool?) ?? false,
      imageUrl: fields[AnimalHiveFields.imageUrl] as String?,
      profileImageUrl: fields[AnimalHiveFields.profileImageUrl] as String?,
      pendingImagePath: fields[AnimalHiveFields.pendingImagePath] as String?,
      ageLabel: (fields[AnimalHiveFields.ageLabel] as String?) ??
          AgeLabelFormatter.format(age),
    );
  }

  @override
  void write(BinaryWriter writer, AnimalModel obj) {
    writer
      ..writeByte(AnimalHiveFields.totalFields)
      ..writeByte(AnimalHiveFields.id)
      ..write(obj.id)
      ..writeByte(AnimalHiveFields.userId)
      ..write(obj.userId)
      ..writeByte(AnimalHiveFields.name)
      ..write(obj.name)
      ..writeByte(AnimalHiveFields.breed)
      ..write(obj.breed)
      ..writeByte(AnimalHiveFields.age)
      ..write(obj.age)
      ..writeByte(AnimalHiveFields.symptoms)
      ..write(obj.symptoms)
      ..writeByte(AnimalHiveFields.createdAt)
      ..write(obj.createdAt)
      ..writeByte(AnimalHiveFields.updatedAt)
      ..write(obj.updatedAt)
      ..writeByte(AnimalHiveFields.weight)
      ..write(obj.weight)
      ..writeByte(AnimalHiveFields.temperature)
      ..write(obj.temperature)
      ..writeByte(AnimalHiveFields.isSynced)
      ..write(obj.isSynced)
      ..writeByte(AnimalHiveFields.imageUrl)
      ..write(obj.imageUrl)
      ..writeByte(AnimalHiveFields.profileImageUrl)
      ..write(obj.profileImageUrl)
      ..writeByte(AnimalHiveFields.pendingImagePath)
      ..write(obj.pendingImagePath)
      ..writeByte(AnimalHiveFields.ageLabel)
      ..write(obj.ageLabel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnimalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
