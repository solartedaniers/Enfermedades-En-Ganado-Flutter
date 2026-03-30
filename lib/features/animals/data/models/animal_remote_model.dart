import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/json_parser.dart';
import '../../domain/entities/animal_entity.dart';
import '../../shared/age_label_formatter.dart';

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

  factory AnimalRemoteModel.fromEntity(AnimalEntity entity) {
    return AnimalRemoteModel(
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
    );
  }

  factory AnimalRemoteModel.fromJson(Map<String, dynamic> json) {
    final ageValue = JsonParser.asInt(json['age']);

    return AnimalRemoteModel(
      id: JsonParser.asString(json['id']) ?? '',
      userId: JsonParser.asString(json['user_id']) ?? '',
      name: JsonParser.asString(json['name']) ?? AppStrings.t('animal_no_name'),
      breed: JsonParser.asString(json['breed']) ??
          AppStrings.t('animal_unknown_breed'),
      age: ageValue,
      ageLabel: AgeLabelFormatter.format(ageValue),
      symptoms: JsonParser.asString(json['symptoms']) ?? '',
      weight: JsonParser.asDouble(json['weight']),
      temperature: JsonParser.asDouble(json['temperature']),
      imageUrl: JsonParser.asString(json['image_url']),
      profileImageUrl: JsonParser.asString(json['profile_image_url']),
      createdAt: JsonParser.asDateTime(json['created_at']),
      updatedAt: JsonParser.asDateTime(json['updated_at']),
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
