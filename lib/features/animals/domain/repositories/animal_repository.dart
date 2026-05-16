import '../entities/animal_entity.dart';

/// Contrato del repositorio de animales.
/// Define las operaciones disponibles sin acoplar a ninguna implementación.
abstract class AnimalRepository {
  /// Agrega un animal nuevo con soporte offline-first.
  /// [localImagePath] ruta local de la imagen pendiente por subir.
  Future<void> addAnimal(AnimalEntity animal, {String? localImagePath});

  /// Retorna la lista de animales del usuario actual.
  Future<List<AnimalEntity>> getAnimals();

  /// Actualiza un animal existente en local y en Supabase.
  Future<void> updateAnimal(AnimalEntity animal, {String? localImagePath});

  /// Elimina el animal de Hive y de Supabase.
  Future<void> deleteAnimal(String id);

  /// Sincroniza animales pendientes cuando regresa la conexión.
  Future<void> syncAnimals();
}
