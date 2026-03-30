import 'package:hive/hive.dart';
import '../../domain/constants/animal_constants.dart';
import '../models/animal_model.dart';

class AnimalLocalDataSource {
  Future<Box<AnimalModel>> _openBox() async {
    return await Hive.openBox<AnimalModel>(AnimalConstants.localBoxName);
  }

  Future<void> saveAnimal(AnimalModel animal) async {
    final box = await _openBox();
    await box.put(animal.id, animal);
  }

  Future<void> syncFromRemote(List<AnimalModel> remoteAnimals) async {
    final box = await _openBox();
    await box.clear();
    for (final remoteAnimal in remoteAnimals) {
      await box.put(remoteAnimal.id, remoteAnimal);
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
        // Usamos copyWith para no perder ningún campo al marcar como synced
        animal.copyWith(isSynced: true),
      );
    }
  }

  Future<void> deleteAnimal(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
}
