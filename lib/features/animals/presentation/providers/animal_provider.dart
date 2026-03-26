import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/animal_local_datasource.dart';
import '../../data/datasources/animal_remote_datasource.dart';
import '../../data/repositories/animal_repository_impl.dart';
import '../../domain/usecases/add_animal.dart';
import '../../domain/usecases/get_animals.dart';

final animalRepositoryProvider = Provider((ref) {
  return AnimalRepositoryImpl(
    localDataSource: AnimalLocalDataSource(),
    remoteDataSource: AnimalRemoteDataSource(),
  );
});

final addAnimalProvider = Provider((ref) {
  final animalRepository = ref.read(animalRepositoryProvider);
  return AddAnimal(animalRepository);
});

final getAnimalsProvider = Provider((ref) {
  final animalRepository = ref.read(animalRepositoryProvider);
  return GetAnimals(animalRepository);
});
