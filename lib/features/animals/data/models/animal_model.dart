import 'package:hive/hive.dart';

import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/animal_entity.dart';
import '../../shared/age_label_formatter.dart';

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
  final String? pendingImagePath;

  @HiveField(14)
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
    final age = (fields[4] as int?) ?? 0;

    return AnimalModel(
      id: (fields[0] as String?) ?? '',
      userId: (fields[1] as String?) ?? '',
      name: (fields[2] as String?) ?? AppStrings.t('animal_no_name'),
      breed: (fields[3] as String?) ?? AppStrings.t('animal_unknown_breed'),
      age: age,
      symptoms: (fields[5] as String?) ?? '',
      createdAt: (fields[6] as DateTime?) ?? DateTime.now(),
      updatedAt: (fields[7] as DateTime?) ?? DateTime.now(),
      weight: fields[8] as double?,
      temperature: fields[9] as double?,
      isSynced: (fields[10] as bool?) ?? false,
      imageUrl: fields[11] as String?,
      profileImageUrl: fields[12] as String?,
      pendingImagePath: fields[13] as String?,
      ageLabel: (fields[14] as String?) ?? AgeLabelFormatter.format(age),
    );
  }

  @override
  void write(BinaryWriter writer, AnimalModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.breed)
      ..writeByte(4)
      ..write(obj.age)
      ..writeByte(5)
      ..write(obj.symptoms)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.weight)
      ..writeByte(9)
      ..write(obj.temperature)
      ..writeByte(10)
      ..write(obj.isSynced)
      ..writeByte(11)
      ..write(obj.imageUrl)
      ..writeByte(12)
      ..write(obj.profileImageUrl)
      ..writeByte(13)
      ..write(obj.pendingImagePath)
      ..writeByte(14)
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
