import '../entities/animal_entity.dart';
import '../repositories/animal_repository.dart';

/// Caso de uso: obtener la lista de animales del usuario.
class GetAnimals {
  final AnimalRepository _repository;

  GetAnimals(this._repository);

  Future<List<AnimalEntity>> call() {
    return _repository.getAnimals();
  }
}
