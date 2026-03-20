import '../entities/animal_entity.dart';
import '../repositories/animal_repository.dart';

class AddAnimal {
  final AnimalRepository repository;

  AddAnimal(this.repository);

  Future<void> call(AnimalEntity animal) async {
    return await repository.addAnimal(animal);
  }
}