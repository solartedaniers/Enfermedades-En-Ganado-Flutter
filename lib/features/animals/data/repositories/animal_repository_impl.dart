import '../../domain/entities/animal_entity.dart';
import '../../domain/repositories/animal_repository.dart';
import '../datasources/animal_local_datasource.dart';
import '../datasources/animal_remote_datasource.dart';
import '../models/animal_model.dart';

class AnimalRepositoryImpl implements AnimalRepository {
  final AnimalLocalDataSource localDataSource;
  final AnimalRemoteDataSource remoteDataSource;

  AnimalRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<void> addAnimal(AnimalEntity animal) async {
    final model = AnimalModel.fromEntity(animal, isSynced: false);

    await localDataSource.saveAnimal(model);

    try {
      await remoteDataSource.insertAnimal(model);
      await localDataSource.markAsSynced(model.id);
    } catch (e) {
      // Sin internet → queda pendiente para sincronización futura
    }
  }

  @override
  Future<List<AnimalEntity>> getAnimals() async {
    final models = await localDataSource.getAnimals();
    return models.map((m) => m.toEntity()).toList();
  }

  Future<void> syncAnimals() async {
    final unsynced = await localDataSource.getUnsyncedAnimals();

    for (final animal in unsynced) {
      try {
        await remoteDataSource.insertAnimal(animal);
        await localDataSource.markAsSynced(animal.id);
      } catch (e) {
        // Si falla, se seguirá intentando luego
      }
    }
  }
}