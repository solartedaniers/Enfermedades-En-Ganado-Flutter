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

  /// Crear animal (offline-first)
  @override
  Future<void> addAnimal(AnimalEntity animal) async {
    final model = AnimalModel(
      id: animal.id,
      name: animal.name,
      breed: animal.breed,
      age: animal.age,
      symptoms: animal.symptoms,
      createdAt: animal.createdAt,
      updatedAt: animal.updatedAt,
      weight: animal.weight,
      temperature: animal.temperature,
      imageUrl: animal.imageUrl,
      isSynced: false, // 👈 CLAVE
    );

    // 1. Guardar LOCAL
    await localDataSource.saveAnimal(model);

    // 2. Intentar sincronizar
    try {
      await remoteDataSource.insertAnimal(model);
      await localDataSource.markAsSynced(model.id);
    } catch (e) {
      // ❌ Sin internet → queda pendiente
    }
  }

  /// Obtener animales (prioridad local)
  @override
  Future<List<AnimalEntity>> getAnimals() async {
    return await localDataSource.getAnimals();
  }

  /// 🔥 SINCRONIZACIÓN MANUAL
  Future<void> syncAnimals() async {
    final unsynced = await localDataSource.getUnsyncedAnimals();

    for (final animal in unsynced) {
      try {
        await remoteDataSource.insertAnimal(animal);
        await localDataSource.markAsSynced(animal.id);
      } catch (e) {
        // sigue intentando luego
      }
    }
  }
}