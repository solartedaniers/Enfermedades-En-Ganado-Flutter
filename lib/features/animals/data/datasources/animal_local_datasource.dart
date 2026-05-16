import 'package:hive/hive.dart';

import '../../domain/constants/animal_constants.dart';
import '../models/animal_model.dart';

/// Fuente de datos local para animales usando Hive.
/// Responsabilidad única: operaciones CRUD sobre la caja local de Hive.
class AnimalLocalDataSource {
  /// Abre (o reutiliza) la caja Hive de animales.
  Future<Box<AnimalModel>> _openBox() async {
    return Hive.openBox<AnimalModel>(AnimalConstants.localBoxName);
  }

  /// Guarda o reemplaza un animal en la caja local.
  Future<void> saveAnimal(AnimalModel animal) async {
    final box = await _openBox();
    await box.put(animal.id, animal);
  }

  /// Sincroniza la caja local con los datos remotos,
  /// preservando rutas de imagen local de registros existentes.
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

  /// Retorna todos los animales almacenados localmente.
  Future<List<AnimalModel>> getAnimals() async {
    final box = await _openBox();
    return box.values.toList();
  }

  /// Retorna únicamente los animales que aún no han sido sincronizados con el servidor.
  Future<List<AnimalModel>> getUnsyncedAnimals() async {
    final box = await _openBox();
    return box.values.where((animal) => !animal.isSynced).toList();
  }

  /// Marca un animal como sincronizado por su ID.
  Future<void> markAsSynced(String id) async {
    final box = await _openBox();
    final animal = box.get(id);
    if (animal == null) return;

    // Usamos copyWith para no perder ningún campo al marcar como synced.
    await box.put(id, animal.copyWith(isSynced: true));
  }

  /// Elimina un animal de la caja local por su ID.
  Future<void> deleteAnimal(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  /// Marca un animal como eliminado localmente para posterior sincronización.
  Future<void> markAsDeleted(String id) async {
    final box = await _openBox();
    final animal = box.get(id);
    if (animal == null) return;

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
