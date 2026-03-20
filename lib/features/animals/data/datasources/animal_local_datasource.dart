import 'package:hive/hive.dart';
import '../models/animal_model.dart';

class AnimalLocalDataSource {
  static const String boxName = 'animals_box';

  Future<Box<AnimalModel>> _openBox() async {
    return await Hive.openBox<AnimalModel>(boxName);
  }

  /// Guardar animal localmente
  Future<void> saveAnimal(AnimalModel animal) async {
    final box = await _openBox();
    await box.put(animal.id, animal);
  }

  /// Obtener todos los animales
  Future<List<AnimalModel>> getAnimals() async {
    final box = await _openBox();
    return box.values.toList();
  }

  /// Obtener no sincronizados
  Future<List<AnimalModel>> getUnsyncedAnimals() async {
    final box = await _openBox();
    return box.values.where((a) => !a.isSynced).toList();
  }

  /// Marcar como sincronizado
  Future<void> markAsSynced(String id) async {
    final box = await _openBox();
    final animal = box.get(id);

    if (animal != null) {
      final updated = AnimalModel(
        id: animal.id,
        name: animal.name,
        breed: animal.breed,
        age: animal.age,
        symptoms: animal.symptoms,
        createdAt: animal.createdAt,
        updatedAt: DateTime.now(),
        isSynced: true,
        weight: animal.weight,
        temperature: animal.temperature,
        imageUrl: animal.imageUrl,
      );

      await box.put(id, updated);
    }
  }
}