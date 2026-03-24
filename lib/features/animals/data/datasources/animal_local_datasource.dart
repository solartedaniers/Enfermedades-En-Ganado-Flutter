import 'package:hive/hive.dart';
import '../models/animal_model.dart';

class AnimalLocalDataSource {
  static const String boxName = 'animals_box';

  Future<Box<AnimalModel>> _openBox() async {
    return await Hive.openBox<AnimalModel>(boxName);
  }

  Future<void> saveAnimal(AnimalModel animal) async {
    final box = await _openBox();
    await box.put(animal.id, animal);
  }

  Future<void> syncFromRemote(List<AnimalModel> remoteAnimals) async {
    final box = await _openBox();
    await box.clear();
    for (final animal in remoteAnimals) {
      await box.put(animal.id, animal);
    }
  }

  Future<List<AnimalModel>> getAnimals() async {
    final box = await _openBox();
    return box.values.toList();
  }

  Future<List<AnimalModel>> getUnsyncedAnimals() async {
    final box = await _openBox();
    return box.values.where((a) => !a.isSynced).toList();
  }

  Future<void> markAsSynced(String id) async {
    final box = await _openBox();
    final animal = box.get(id);
    if (animal != null) {
      await box.put(
        id,
        AnimalModel(
          id: animal.id,
          userId: animal.userId,
          name: animal.name,
          breed: animal.breed,
          age: animal.age,
          symptoms: animal.symptoms,
          createdAt: animal.createdAt,
          updatedAt: animal.updatedAt,
          weight: animal.weight,
          temperature: animal.temperature,
          imageUrl: animal.imageUrl,
          isSynced: true,
        ),
      );
    }
  }

  Future<void> deleteAnimal(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
}