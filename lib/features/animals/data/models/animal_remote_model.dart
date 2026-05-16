import '../../../../core/constants/app_json_keys.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/json_parser.dart';
import '../../domain/constants/animal_breed_catalog.dart';
import '../../domain/entities/animal_entity.dart';
import '../../shared/age_label_formatter.dart';

/// Modelo de transferencia de datos para la API remota (Supabase).
/// Responsabilidad única: mapeo entre JSON de Supabase y [AnimalEntity].
class AnimalRemoteModel {
  final String id;
  final String userId;
  final String name;
  final String breed;
  final int age;
  final String ageLabel;
  final String symptoms;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? weight;
  final double? temperature;
  final String? imageUrl;
  final String? profileImageUrl;

  const AnimalRemoteModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.breed,
    required this.age,
    required this.ageLabel,
    required this.symptoms,
    required this.createdAt,
    required this.updatedAt,
    this.weight,
    this.temperature,
    this.imageUrl,
    this.profileImageUrl,
  });

  /// Crea un [AnimalRemoteModel] desde una entidad de dominio para enviar a Supabase.
  factory AnimalRemoteModel.fromEntity(AnimalEntity entity) {
    return AnimalRemoteModel(
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
    );
  }

  /// Deserializa la respuesta JSON de Supabase a [AnimalRemoteModel].
  factory AnimalRemoteModel.fromJson(Map<String, dynamic> json) {
    final ageValue = JsonParser.asInt(json[AppJsonKeys.age]);

    return AnimalRemoteModel(
      id: JsonParser.asString(json[AppJsonKeys.id]) ?? '',
      userId: JsonParser.asString(json[AppJsonKeys.userId]) ?? '',
      name: JsonParser.asString(json[AppJsonKeys.name]) ??
          AppStrings.t('animal_no_name'),
      breed: AnimalBreedCatalog.storageValue(
        JsonParser.asString(json[AppJsonKeys.breed]),
      ),
      age: ageValue,
      ageLabel: AgeLabelFormatter.format(ageValue),
      symptoms: JsonParser.asString(json[AppJsonKeys.symptoms]) ?? '',
      weight: JsonParser.asDouble(json[AppJsonKeys.weight]),
      temperature: JsonParser.asDouble(json[AppJsonKeys.temperature]),
      imageUrl: JsonParser.asString(json[AppJsonKeys.imageUrl]),
      profileImageUrl: JsonParser.asString(json[AppJsonKeys.profileImageUrl]),
      createdAt: JsonParser.asDateTime(json[AppJsonKeys.createdAt]),
      updatedAt: JsonParser.asDateTime(json[AppJsonKeys.updatedAt]),
    );
  }

  /// Convierte el modelo remoto a entidad de dominio.
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

  /// Serializa el modelo a JSON para enviar a Supabase.
  Map<String, dynamic> toJson() {
    return {
      AppJsonKeys.id: id,
      AppJsonKeys.userId: userId,
      AppJsonKeys.name: name,
      AppJsonKeys.breed: breed,
      AppJsonKeys.age: age,
      AppJsonKeys.symptoms: symptoms,
      AppJsonKeys.weight: weight,
      AppJsonKeys.temperature: temperature,
      AppJsonKeys.imageUrl: imageUrl,
      AppJsonKeys.profileImageUrl: profileImageUrl,
      AppJsonKeys.createdAt: createdAt.toIso8601String(),
      AppJsonKeys.updatedAt: updatedAt.toIso8601String(),
    };
  }
}
