import 'package:hive/hive.dart';

import '../../domain/constants/animal_constants.dart';
import '../models/animal_model.dart';

class AnimalLocalDataSource {
  Future<Box<AnimalModel>> _openBox() async {
    return Hive.openBox<AnimalModel>(AnimalConstants.localBoxName);
  }

  Future<void> saveAnimal(AnimalModel animal) async {
    final box = await _openBox();
    await box.put(animal.id, animal);
  }

  Future<void> syncFromRemote(List<AnimalModel> remoteAnimals) async {
    final box = await _openBox();
    final existingAnimals = {
      for (final animal in box.values) animal.id: animal,
    };
    await box.clear();

    for (final remoteAnimal in remoteAnimals) {
      final preservedAnimal = existingAnimals[remoteAnimal.id];
      await box.put(
        remoteAnimal.id,
        remoteAnimal.copyWith(
          localProfileImagePath:
              preservedAnimal?.localProfileImagePath ??
              remoteAnimal.localProfileImagePath,
          pendingImagePath:
              preservedAnimal?.pendingImagePath ?? remoteAnimal.pendingImagePath,
        ),
      );
    }
  }

  Future<List<AnimalModel>> getAnimals() async {
    final box = await _openBox();
    return box.values.toList();
  }

  Future<List<AnimalModel>> getUnsyncedAnimals() async {
    final box = await _openBox();
    return box.values.where((animal) => !animal.isSynced).toList();
  }

  Future<void> markAsSynced(String id) async {
    final box = await _openBox();
    final animal = box.get(id);

    if (animal == null) {
      return;
    }

    await box.put(
      id,
      // Usamos copyWith para no perder ningun campo al marcar como synced.
      animal.copyWith(isSynced: true),
    );
  }

  Future<void> deleteAnimal(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  Future<void> markAsDeleted(String id) async {
    final box = await _openBox();
    final animal = box.get(id);

    if (animal == null) {
      return;
    }

    await box.put(
      id,
      animal.copyWith(
        isDeleted: true,
        isSynced: false,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
