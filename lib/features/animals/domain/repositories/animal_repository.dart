import '../entities/animal_entity.dart';

abstract class AnimalRepository {
  /// Agrega o actualiza un animal (offline-first).
  /// [localImagePath] ruta local de imagen pendiente de subir.
  Future<void> addAnimal(AnimalEntity animal, {String? localImagePath});

  Future<List<AnimalEntity>> getAnimals();

  /// Elimina el animal tanto en Hive como en Supabase.
  Future<void> deleteAnimal(String id);

  /// Sincroniza animales pendientes cuando regresa la conexión.
  Future<void> syncAnimals();
}