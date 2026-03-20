import 'package:hive/hive.dart';
import '../../domain/entities/animal_entity.dart';

part 'animal_model.g.dart';

@HiveType(typeId: 0)
class AnimalModel extends AnimalEntity {
  
  // Campo adicional que no existe en la entidad base
  @HiveField(10)
  final bool isSynced;

  AnimalModel({
    required super.id,
    required super.name,
    required super.breed,
    required super.age,
    required super.symptoms,
    required super.createdAt,
    required super.updatedAt,
    this.isSynced = false,
    super.weight,
    super.temperature,
    super.imageUrl,
  }); // 👈 El bloque : super(...) ya no es necesario con esta sintaxis

  factory AnimalModel.fromJson(Map<String, dynamic> json) {
    return AnimalModel(
      id: json['id'],
      name: json['name'],
      breed: json['breed'],
      age: json['age'],
      symptoms: json['symptoms'],
      weight: (json['weight'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isSynced: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'age': age,
      'symptoms': symptoms,
      'weight': weight,
      'temperature': temperature,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}