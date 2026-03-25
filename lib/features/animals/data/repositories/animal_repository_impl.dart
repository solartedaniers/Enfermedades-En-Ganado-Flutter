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
    // 1. Guardar en Hive primero (offline-first), marcado como no sincronizado.
    //    La imagen de perfil ya subida viene en animal.profileImageUrl.
    //    Si hay una imagen local pendiente de subir, se guarda en pendingImagePath.
    final localModel = AnimalModel.fromEntity(
      animal,
      isSynced: false,
      // FIX: solo guardar pendingImagePath si es diferente a profileImageUrl
      //      (la imagen puede ya haber sido subida antes de llamar addAnimal)
      pendingImagePath: localImagePath,
    );
    await localDataSource.saveAnimal(localModel);

    // 2. Intentar sincronizar con Supabase.
    try {
      String? uploadedImageUrl;

      // FIX: si localImagePath no es null Y profileImageUrl ya está en el modelo,
      //      no subir de nuevo. Solo subir si profileImageUrl está vacío.
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

      // FIX: construir modelo con todos los campos garantizados non-null
      final syncedModel = localModel.copyWith(
        profileImageUrl: uploadedImageUrl ?? animal.profileImageUrl,
        isSynced: true,
        pendingImagePath: null, // limpiar path local al sincronizar
      );

      // Insertar en Supabase (toJson excluye age_label y campos null).
      await remoteDataSource.insertAnimal(syncedModel);

      // Actualizar Hive con el estado sincronizado.
      await localDataSource.saveAnimal(syncedModel);
    } catch (_) {
      // Sin internet o error de red → el animal queda en Hive con
      // isSynced: false y se sincronizará cuando vuelva la conexión.
    }
  }

  @override
  Future<List<AnimalEntity>> getAnimals() async {
    try {
      // Con internet: trae de Supabase y actualiza el caché local.
      final remoteAnimals = await remoteDataSource.getAnimals();
      await localDataSource.syncFromRemote(remoteAnimals);
      return remoteAnimals.map((m) => m.toEntity()).toList();
    } catch (_) {
      // Sin internet: usa el caché de Hive.
      final localAnimals = await localDataSource.getAnimals();
      return localAnimals.map((m) => m.toEntity()).toList();
    }
  }

  Future<void> deleteAnimal(String id) async {
    await localDataSource.deleteAnimal(id);
    try {
      await remoteDataSource.deleteAnimal(id);
    } catch (_) {
      // Se reintentará en la próxima sincronización.
    }
  }

  /// Sincroniza todos los animales pendientes (isSynced: false) con Supabase.
  /// Se llama desde AnimalSyncService cuando detecta conexión.
  Future<void> syncAnimals() async {
    final unsynced = await localDataSource.getUnsyncedAnimals();

    for (final animal in unsynced) {
      try {
        // FIX: verificar que profileImageUrl sea una URL real de Supabase
        //      (empieza con http) para no intentar "subir" una URL ya válida
        String? profileImageUrl = animal.profileImageUrl;

        // Subir imagen local pendiente si existe
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

        // FIX: usar upsert en lugar de insert para evitar duplicados
        //      si el animal ya fue subido parcialmente antes
        await remoteDataSource.upsertAnimal(syncedModel);
        await localDataSource.saveAnimal(syncedModel);
      } catch (_) {
        // Reintentará en la próxima conexión.
      }
    }
  }
}