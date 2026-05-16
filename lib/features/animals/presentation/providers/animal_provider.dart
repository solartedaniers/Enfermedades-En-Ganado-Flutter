import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/storage_service.dart';
import '../../../profile/presentation/providers/managed_client_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/datasources/animal_local_datasource.dart';
import '../../data/datasources/animal_remote_datasource.dart';
import '../../data/repositories/animal_repository_impl.dart';
import '../../data/services/animal_image_resolver.dart';
import '../../domain/entities/animal_entity.dart';
import '../../domain/usecases/add_animal.dart';
import '../../domain/usecases/get_animals.dart';

// ---------------------------------------------------------------------------
// Señal de refresco
// ---------------------------------------------------------------------------

/// Señal para forzar la recarga de la lista de animales.
final animalsRefreshSignalProvider = StateProvider<int>((ref) => 0);

// ---------------------------------------------------------------------------
// Infraestructura
// ---------------------------------------------------------------------------

/// Proveedor del cliente Supabase.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Proveedor del ID del usuario autenticado actualmente.
final currentUserIdProvider = Provider<String?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser?.id ?? ref.watch(profileProvider).userId;
});

/// Proveedor del servicio de almacenamiento de archivos.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(supabaseClientProvider));
});

/// Proveedor del resolutor de imágenes de animales.
final animalImageResolverProvider = Provider<AnimalImageResolver>((ref) {
  return AnimalImageResolver(ref.watch(storageServiceProvider));
});

// ---------------------------------------------------------------------------
// Fuentes de datos
// ---------------------------------------------------------------------------

/// Proveedor de la fuente de datos local (Hive).
final animalLocalDataSourceProvider = Provider<AnimalLocalDataSource>((ref) {
  return AnimalLocalDataSource();
});

/// Proveedor de la fuente de datos remota (Supabase).
final animalRemoteDataSourceProvider = Provider<AnimalRemoteDataSource>((ref) {
  return AnimalRemoteDataSource(ref.watch(supabaseClientProvider));
});

// ---------------------------------------------------------------------------
// Repositorio
// ---------------------------------------------------------------------------

/// Proveedor del repositorio de animales.
final animalRepositoryProvider = Provider<AnimalRepositoryImpl>((ref) {
  return AnimalRepositoryImpl(
    localDataSource: ref.watch(animalLocalDataSourceProvider),
    remoteDataSource: ref.watch(animalRemoteDataSourceProvider),
    imageResolver: ref.watch(animalImageResolverProvider),
  );
});

// ---------------------------------------------------------------------------
// Casos de uso
// ---------------------------------------------------------------------------

/// Proveedor del caso de uso AddAnimal.
final addAnimalProvider = Provider<AddAnimal>((ref) {
  return AddAnimal(ref.read(animalRepositoryProvider));
});

/// Proveedor del caso de uso GetAnimals.
final getAnimalsProvider = Provider<GetAnimals>((ref) {
  return GetAnimals(ref.read(animalRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Providers de lista
// ---------------------------------------------------------------------------

/// Lista cruda de animales del usuario actual sin filtrar por cliente veterinario.
final rawAnimalsListProvider =
    FutureProvider.autoDispose<List<AnimalEntity>>((ref) async {
  ref.watch(animalsRefreshSignalProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  final animals = await ref.watch(getAnimalsProvider).call();

  if (currentUserId == null) return animals;
  return animals.where((a) => a.userId == currentUserId).toList();
});

/// Lista de animales filtrada según el rol del usuario.
/// Para veterinarios, filtra por el cliente activo.
final animalsListProvider =
    FutureProvider.autoDispose<List<AnimalEntity>>((ref) async {
  ref.watch(animalsRefreshSignalProvider);
  final animals = await ref.watch(rawAnimalsListProvider.future);
  final currentUserId = ref.watch(currentUserIdProvider);
  final profile = ref.watch(profileProvider);

  final scopedAnimals = currentUserId == null
      ? animals
      : animals.where((a) => a.userId == currentUserId).toList();

  if (!profile.isVeterinarian) return scopedAnimals;

  final managedClientState = await ref.watch(managedClientProvider.future);
  final activeClientId = managedClientState.activeClientId;

  if (activeClientId == null) return const [];

  return scopedAnimals
      .where((a) => managedClientState.animalAssignments[a.id] == activeClientId)
      .toList();
});

/// Retorna un animal específico por ID desde la lista cruda.
final animalByIdProvider =
    Provider.autoDispose.family<AsyncValue<AnimalEntity?>, String>((ref, id) {
  return ref.watch(rawAnimalsListProvider).whenData(
        (animals) => animals.firstWhere((a) => a.id == id, orElse: () => null as dynamic),
      );
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Incrementa la señal de refresco para recargar la lista de animales.
void refreshAnimals(WidgetRef ref) {
  ref.read(animalsRefreshSignalProvider.notifier).state++;
}
