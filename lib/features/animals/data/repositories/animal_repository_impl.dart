import 'dart:io';

import '../../../../core/services/storage_service.dart';
import '../../domain/entities/animal_entity.dart';
import '../../domain/repositories/animal_repository.dart';
import '../datasources/animal_local_datasource.dart';
import '../datasources/animal_remote_datasource.dart';
import '../models/animal_model.dart';

class AnimalRepositoryImpl implements AnimalRepository {
  final AnimalLocalDataSource localDataSource;
  final AnimalRemoteDataSource remoteDataSource;
  final StorageService storageService;

  AnimalRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.storageService,
  });

  @override
  Future<void> addAnimal(AnimalEntity animal, {String? localImagePath}) async {
    final localModel = AnimalModel.fromEntity(
      animal,
      isSynced: false,
      pendingImagePath: localImagePath,
    );
    await localDataSource.saveAnimal(localModel);

    try {
      final uploadedImageUrl = await _resolveImageUrl(
        userId: animal.userId,
        localImagePath: localImagePath,
        currentImageUrl: animal.profileImageUrl,
      );

      final syncedModel = localModel.copyWith(
        profileImageUrl: uploadedImageUrl ?? animal.profileImageUrl,
        isSynced: true,
        pendingImagePath: null,
      );

      await remoteDataSource.insertAnimal(syncedModel.toEntity());
      await localDataSource.saveAnimal(syncedModel);
    } catch (_) {
      // El animal queda guardado localmente y pendiente de sincronizar.
    }
  }

  @override
  Future<List<AnimalEntity>> getAnimals() async {
    try {
      final remoteAnimals = await remoteDataSource.getAnimals();
      final pendingLocalAnimals = await localDataSource.getUnsyncedAnimals();
      final mergedAnimals = <String, AnimalModel>{
        for (final animal in remoteAnimals)
          animal.id: AnimalModel.fromEntity(animal, isSynced: true),
      };

      for (final pendingAnimal in pendingLocalAnimals) {
        mergedAnimals[pendingAnimal.id] = pendingAnimal;
      }

      await localDataSource.syncFromRemote(mergedAnimals.values.toList());
      return mergedAnimals.values
          .where((animal) => !animal.isDeleted)
          .map((animal) => animal.toEntity())
          .toList();
    } catch (_) {
      final localAnimals = await localDataSource.getAnimals();
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
    await localDataSource.saveAnimal(localModel);

    try {
      final uploadedImageUrl = await _resolveImageUrl(
        userId: animal.userId,
        localImagePath: localImagePath,
        currentImageUrl: animal.profileImageUrl,
      );

      final syncedModel = localModel.copyWith(
        profileImageUrl: uploadedImageUrl,
        isSynced: true,
        pendingImagePath: null,
      );

      await remoteDataSource.updateAnimal(syncedModel.toEntity());
      await localDataSource.saveAnimal(syncedModel);
    } catch (_) {
      // Queda actualizado en local y podra sincronizarse luego.
    }
  }

  @override
  Future<void> deleteAnimal(String id) async {
    await localDataSource.markAsDeleted(id);
    try {
      await remoteDataSource.deleteAnimal(id);
      await localDataSource.deleteAnimal(id);
    } catch (_) {
      // Reintento pendiente.
    }
  }

  @override
  Future<void> syncAnimals() async {
    final pendingAnimals = await localDataSource.getUnsyncedAnimals();

    for (final pendingAnimal in pendingAnimals) {
      try {
        if (pendingAnimal.isDeleted) {
          await remoteDataSource.deleteAnimal(pendingAnimal.id);
          await localDataSource.deleteAnimal(pendingAnimal.id);
          continue;
        }

        final profileImageUrl = await _resolveImageUrl(
          userId: pendingAnimal.userId,
          localImagePath: pendingAnimal.pendingImagePath,
          currentImageUrl: pendingAnimal.profileImageUrl,
        );

        final syncedModel = pendingAnimal.copyWith(
          profileImageUrl: profileImageUrl,
          isSynced: true,
          pendingImagePath: null,
        );

        await remoteDataSource.upsertAnimal(syncedModel.toEntity());
        await localDataSource.saveAnimal(syncedModel);
      } catch (_) {
        // Reintentara luego.
      }
    }
  }

  Future<String?> _resolveImageUrl({
    required String userId,
    required String? localImagePath,
    required String? currentImageUrl,
  }) async {
    if (localImagePath == null || localImagePath.isEmpty) {
      return currentImageUrl;
    }

    final file = File(localImagePath);
    if (!await file.exists()) {
      return currentImageUrl;
    }

    return storageService.uploadAnimalImage(file, userId);
  }
}
