import 'package:hive/hive.dart';

import '../../../../core/constants/app_storage_keys.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/constants/animal_breed_catalog.dart';
import '../../shared/age_label_formatter.dart';
import 'animal_model.dart';

/// Adaptador Hive para [AnimalModel].
/// Responsabilidad única: serialización binaria de AnimalModel para Hive.
/// Separado del modelo para cumplir el principio de responsabilidad única.
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
      breed: AnimalBreedCatalog.storageValue(
        fields[AnimalHiveFields.breed] as String?,
      ),
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
      isDeleted: (fields[AnimalHiveFields.isDeleted] as bool?) ?? false,
      localProfileImagePath:
          fields[AnimalHiveFields.localProfileImagePath] as String?,
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
      ..write(obj.ageLabel)
      ..writeByte(AnimalHiveFields.isDeleted)
      ..write(obj.isDeleted)
      ..writeByte(AnimalHiveFields.localProfileImagePath)
      ..write(obj.localProfileImagePath);
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
