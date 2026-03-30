import '../entities/animal_entity.dart';

abstract class AnimalRepository {
  /// Agrega o actualiza un animal (offline-first).
  /// [localImagePath] es la ruta local de una imagen pendiente por subir.
  Future<void> addAnimal(AnimalEntity animal, {String? localImagePath});

  Future<List<AnimalEntity>> getAnimals();

  /// Actualiza un animal existente tanto en local como en Supabase.
  Future<void> updateAnimal(AnimalEntity animal, {String? localImagePath});

  /// Elimina el animal tanto en Hive como en Supabase.
  Future<void> deleteAnimal(String id);

  /// Sincroniza animales pendientes cuando regresa la conexion.
  Future<void> syncAnimals();
}
