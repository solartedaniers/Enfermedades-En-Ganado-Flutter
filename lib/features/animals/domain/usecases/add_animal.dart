import '../entities/animal_entity.dart';
import '../repositories/animal_repository.dart';

/// Caso de uso: agregar un animal nuevo al sistema.
class AddAnimal {
  final AnimalRepository _repository;

  AddAnimal(this._repository);

  Future<void> call(AnimalEntity animal, {String? localImagePath}) {
    return _repository.addAnimal(animal, localImagePath: localImagePath);
  }
}
