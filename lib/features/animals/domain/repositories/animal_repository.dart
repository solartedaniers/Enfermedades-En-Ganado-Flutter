import '../entities/animal_entity.dart';

abstract class AnimalRepository {
  /// [localImagePath] ruta local de la imagen cuando no hay internet.
  /// El repositorio decide si sube ahora o lo guarda como pendiente.
  Future<void> addAnimal(AnimalEntity animal, {String? localImagePath});
  Future<List<AnimalEntity>> getAnimals();
  Future<void> syncAnimals();
}