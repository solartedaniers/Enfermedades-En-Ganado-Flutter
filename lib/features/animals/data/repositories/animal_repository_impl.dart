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
    // Guarda siempre en local primero
    final model = AnimalModel.fromEntity(
      animal,
      isSynced: false,
      pendingImagePath: localImagePath,
    );
    await localDataSource.saveAnimal(model);

    // Intenta sincronizar con Supabase
    try {
      String? imageUrl;

      // Si hay imagen local pendiente, súbela
      if (localImagePath != null) {
        imageUrl = await _storageService.uploadAnimalImage(
          File(localImagePath),
          animal.userId,
        );
      }

      final syncedModel = model.copyWith(
        imageUrl: imageUrl ?? animal.imageUrl,
        isSynced: true,
        pendingImagePath: null,
      );

      await remoteDataSource.insertAnimal(syncedModel);
      await localDataSource.saveAnimal(syncedModel);
    } catch (e) {
      // Sin internet → queda en local con pendingImagePath
    }
  }

  @override
  Future<List<AnimalEntity>> getAnimals() async {
    try {
      final remoteAnimals = await remoteDataSource.getAnimals();
      await localDataSource.syncFromRemote(remoteAnimals);
      return remoteAnimals.map((m) => m.toEntity()).toList();
    } catch (e) {
      // Sin internet → usa cache local
      final localAnimals = await localDataSource.getAnimals();
      return localAnimals.map((m) => m.toEntity()).toList();
    }
  }

  // Se eliminó el @override si no está definido en el contrato/interfaz
  Future<void> deleteAnimal(String id) async {
    await localDataSource.deleteAnimal(id);
    try {
      await remoteDataSource.deleteAnimal(id);
    } catch (e) {
      // Se reintentará en la próxima sync
    }
  }

  /// Sincroniza animales pendientes incluyendo imágenes
  // SE ELIMINÓ EL @override AQUÍ PARA QUITAR LA ADVERTENCIA
  Future<void> syncAnimals() async {
    final unsynced = await localDataSource.getUnsyncedAnimals();

    for (final animal in unsynced) {
      try {
        String? imageUrl = animal.imageUrl;

        // Si tiene imagen local pendiente, súbela ahora que hay internet
        if (animal.pendingImagePath != null) {
          final file = File(animal.pendingImagePath!);
          if (await file.exists()) {
            imageUrl = await _storageService.uploadAnimalImage(
              file,
              animal.userId,
            );
          }
        }

        final syncedModel = animal.copyWith(
          imageUrl: imageUrl,
          isSynced: true,
          pendingImagePath: null,
        );

        await remoteDataSource.insertAnimal(syncedModel);
        await localDataSource.saveAnimal(syncedModel);
      } catch (e) {
        // Reintentará en la próxima conexión
      }
    }
  }
}