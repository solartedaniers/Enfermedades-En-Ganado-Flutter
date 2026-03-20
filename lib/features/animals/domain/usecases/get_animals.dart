import '../entities/animal_entity.dart';
import '../repositories/animal_repository.dart';

class GetAnimals {
  final AnimalRepository repository;

  GetAnimals(this.repository);

  Future<List<AnimalEntity>> call() async {
    return await repository.getAnimals();
  }
}