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
  final StorageService _storageService = StorageService();

  AnimalRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
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
      String? uploadedImageUrl;

      if (localImagePath != null &&
          (animal.profileImageUrl == null ||
              animal.profileImageUrl!.isEmpty)) {
        final file = File(localImagePath);
        if (await file.exists()) {
          uploadedImageUrl = await _storageService.uploadAnimalImage(
            file,
            animal.userId,
          );
        }
      }

      final syncedModel = localModel.copyWith(
        profileImageUrl: uploadedImageUrl ?? animal.profileImageUrl,
        isSynced: true,
        pendingImagePath: null,
      );

      await remoteDataSource.insertAnimal(syncedModel);
      await localDataSource.saveAnimal(syncedModel);
    } catch (_) {
      // El animal queda guardado localmente y pendiente de sincronizar.
    }
  }

  @override
  Future<List<AnimalEntity>> getAnimals() async {
    try {
      final remoteAnimals = await remoteDataSource.getAnimals();
      await localDataSource.syncFromRemote(remoteAnimals);
      return remoteAnimals.map((model) => model.toEntity()).toList();
    } catch (_) {
      final localAnimals = await localDataSource.getAnimals();
      return localAnimals.map((model) => model.toEntity()).toList();
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
      String? uploadedImageUrl = animal.profileImageUrl;

      if (localImagePath != null &&
          (animal.profileImageUrl == null ||
              animal.profileImageUrl!.isEmpty)) {
        final file = File(localImagePath);
        if (await file.exists()) {
          uploadedImageUrl = await _storageService.uploadAnimalImage(
            file,
            animal.userId,
          );
        }
      }

      final syncedModel = localModel.copyWith(
        profileImageUrl: uploadedImageUrl,
        isSynced: true,
        pendingImagePath: null,
      );

      await remoteDataSource.updateAnimal(syncedModel);
      await localDataSource.saveAnimal(syncedModel);
    } catch (_) {
      // Queda actualizado en local y podra sincronizarse luego.
    }
  }

  @override
  Future<void> deleteAnimal(String id) async {
    await localDataSource.deleteAnimal(id);
    try {
      await remoteDataSource.deleteAnimal(id);
    } catch (_) {
      // Reintento pendiente.
    }
  }

  @override
  Future<void> syncAnimals() async {
    final unsynced = await localDataSource.getUnsyncedAnimals();

    for (final animal in unsynced) {
      try {
        String? profileImageUrl = animal.profileImageUrl;

        if (animal.pendingImagePath != null) {
          final file = File(animal.pendingImagePath!);
          if (await file.exists()) {
            profileImageUrl = await _storageService.uploadAnimalImage(
              file,
              animal.userId,
            );
          }
        }

        final syncedModel = animal.copyWith(
          profileImageUrl: profileImageUrl,
          isSynced: true,
          pendingImagePath: null,
        );

        await remoteDataSource.upsertAnimal(syncedModel);
        await localDataSource.saveAnimal(syncedModel);
      } catch (_) {
        // Reintentara luego.
      }
    }
  }
}
