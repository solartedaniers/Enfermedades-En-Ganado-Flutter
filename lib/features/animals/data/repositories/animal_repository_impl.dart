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
      // Sin internet → queda pendiente
    }
  }

  // Primero intenta traer desde Supabase y sincroniza local
  @override
  Future<List<AnimalEntity>> getAnimals() async {
    try {
      final remoteAnimals = await remoteDataSource.getAnimals();
      await localDataSource.syncFromRemote(remoteAnimals);
      return remoteAnimals.map((m) => m.toEntity()).toList();
    } catch (e) {
      // Sin internet → usa local
      final localAnimals = await localDataSource.getAnimals();
      return localAnimals.map((m) => m.toEntity()).toList();
    }
  }

  Future<void> deleteAnimal(String id) async {
    await localDataSource.deleteAnimal(id);
    try {
      await remoteDataSource.deleteAnimal(id);
    } catch (e) {
      // Sin internet → se borrará cuando haya conexión
    }
  }

  Future<void> syncAnimals() async {
    final unsynced = await localDataSource.getUnsyncedAnimals();
    for (final animal in unsynced) {
      try {
        await remoteDataSource.insertAnimal(animal);
        await localDataSource.markAsSynced(animal.id);
      } catch (e) {
        // Reintentará luego
      }
    }
  }
}