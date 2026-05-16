import '../../domain/entities/animal_entity.dart';
import '../../domain/repositories/animal_repository.dart';
import '../datasources/animal_local_datasource.dart';
import '../datasources/animal_remote_datasource.dart';
import '../models/animal_model.dart';
import '../services/animal_image_resolver.dart';

/// Implementación del repositorio de animales.
/// Coordina la fuente local (Hive) y la remota (Supabase) con estrategia offline-first.
class AnimalRepositoryImpl implements AnimalRepository {
  final AnimalLocalDataSource _localDataSource;
  final AnimalRemoteDataSource _remoteDataSource;
  final AnimalImageResolver _imageResolver;

  AnimalRepositoryImpl({
    required AnimalLocalDataSource localDataSource,
    required AnimalRemoteDataSource remoteDataSource,
    required AnimalImageResolver imageResolver,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _imageResolver = imageResolver;

  @override
  Future<void> addAnimal(AnimalEntity animal, {String? localImagePath}) async {
    // Guarda localmente primero para garantizar persistencia offline.
    final localModel = AnimalModel.fromEntity(
      animal,
      isSynced: false,
      pendingImagePath: localImagePath,
    );
    await _localDataSource.saveAnimal(localModel);

    try {
      final uploadedImageUrl = await _imageResolver.resolve(
        userId: animal.userId,
        localImagePath: localImagePath,
        currentImageUrl: animal.profileImageUrl,
      );

      final syncedModel = localModel.copyWith(
        profileImageUrl: uploadedImageUrl ?? animal.profileImageUrl,
        localProfileImagePath: localImagePath ?? animal.localProfileImagePath,
        isSynced: true,
        pendingImagePath: null,
      );

      await _remoteDataSource.insertAnimal(syncedModel.toEntity());
      await _localDataSource.saveAnimal(syncedModel);
    } catch (_) {
      // El animal queda guardado localmente y pendiente de sincronizar.
    }
  }

  @override
  Future<List<AnimalEntity>> getAnimals() async {
    try {
      final remoteAnimals = await _remoteDataSource.getAnimals();
      final pendingLocalAnimals = await _localDataSource.getUnsyncedAnimals();

      final mergedAnimals = <String, AnimalModel>{
        for (final animal in remoteAnimals)
          animal.id: AnimalModel.fromEntity(animal, isSynced: true),
      };

      // Los pendientes locales tienen prioridad sobre los remotos.
      for (final pendingAnimal in pendingLocalAnimals) {
        mergedAnimals[pendingAnimal.id] = pendingAnimal;
      }

      await _localDataSource.syncFromRemote(mergedAnimals.values.toList());

      return mergedAnimals.values
          .where((animal) => !animal.isDeleted)
          .map((animal) => animal.toEntity())
          .toList();
    } catch (_) {
      // Fallback a datos locales si no hay conexión.
      final localAnimals = await _localDataSource.getAnimals();
      return localAnimals
          .where((animal) => !animal.isDeleted)
          .map((model) => model.toEntity())
          .toList();
    }
  }

  @override
  Future<void> updateAnimal(
    AnimalEntity animal, {
    String? localImagePath,
  }) async {
    final localModel = AnimalModel.fromEntity(
      animal,
      isSynced: false,
      pendingImagePath: localImagePath,
    );
    await _localDataSource.saveAnimal(localModel);

    try {
      final uploadedImageUrl = await _imageResolver.resolve(
        userId: animal.userId,
        localImagePath: localImagePath,
        currentImageUrl: animal.profileImageUrl,
      );

      final syncedModel = localModel.copyWith(
        profileImageUrl: uploadedImageUrl ?? animal.profileImageUrl,
        localProfileImagePath: localImagePath ?? animal.localProfileImagePath,
        isSynced: true,
        pendingImagePath: null,
      );

      await _remoteDataSource.updateAnimal(syncedModel.toEntity());
      await _localDataSource.saveAnimal(syncedModel);
    } catch (_) {
      // Queda actualizado en local y podrá sincronizarse luego.
    }
  }

  @override
  Future<void> deleteAnimal(String id) async {
    await _localDataSource.markAsDeleted(id);
    try {
      await _remoteDataSource.deleteAnimal(id);
      await _localDataSource.deleteAnimal(id);
    } catch (_) {
      // Reintento pendiente cuando haya conexión.
    }
  }

  @override
  Future<void> syncAnimals() async {
    final pendingAnimals = await _localDataSource.getUnsyncedAnimals();

    for (final pendingAnimal in pendingAnimals) {
      try {
        if (pendingAnimal.isDeleted) {
          await _remoteDataSource.deleteAnimal(pendingAnimal.id);
          await _localDataSource.deleteAnimal(pendingAnimal.id);
          continue;
        }

        final profileImageUrl = await _imageResolver.resolve(
          userId: pendingAnimal.userId,
          localImagePath: pendingAnimal.pendingImagePath,
          currentImageUrl: pendingAnimal.profileImageUrl,
        );

        final syncedModel = pendingAnimal.copyWith(
          profileImageUrl: profileImageUrl,
          localProfileImagePath:
              pendingAnimal.pendingImagePath ??
              pendingAnimal.localProfileImagePath,
          isSynced: true,
          pendingImagePath: null,
        );

        await _remoteDataSource.upsertAnimal(syncedModel.toEntity());
        await _localDataSource.saveAnimal(syncedModel);
      } catch (_) {
        // Reintentará en el próximo ciclo de sincronización.
      }
    }
  }
}
