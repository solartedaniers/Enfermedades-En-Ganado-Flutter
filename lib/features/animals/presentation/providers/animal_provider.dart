import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/storage_service.dart';
import '../../../profile/presentation/providers/managed_client_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/datasources/animal_local_datasource.dart';
import '../../data/datasources/animal_remote_datasource.dart';
import '../../data/repositories/animal_repository_impl.dart';
import '../../domain/entities/animal_entity.dart';
import '../../domain/usecases/add_animal.dart';
import '../../domain/usecases/get_animals.dart';

final animalsRefreshSignalProvider = StateProvider<int>((ref) => 0);

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser?.id ?? ref.watch(profileProvider).userId;
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return StorageService(supabaseClient);
});

final animalLocalDataSourceProvider = Provider<AnimalLocalDataSource>((ref) {
  return AnimalLocalDataSource();
});

final animalRemoteDataSourceProvider = Provider<AnimalRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return AnimalRemoteDataSource(supabaseClient);
});

final animalRepositoryProvider = Provider<AnimalRepositoryImpl>((ref) {
  return AnimalRepositoryImpl(
    localDataSource: ref.watch(animalLocalDataSourceProvider),
    remoteDataSource: ref.watch(animalRemoteDataSourceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

final addAnimalProvider = Provider<AddAnimal>((ref) {
  final animalRepository = ref.read(animalRepositoryProvider);
  return AddAnimal(animalRepository);
});

final getAnimalsProvider = Provider<GetAnimals>((ref) {
  final animalRepository = ref.read(animalRepositoryProvider);
  return GetAnimals(animalRepository);
});

final rawAnimalsListProvider =
    FutureProvider.autoDispose<List<AnimalEntity>>((ref) async {
  ref.watch(animalsRefreshSignalProvider);
  final getAnimals = ref.watch(getAnimalsProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  final animals = await getAnimals();

  if (currentUserId == null) {
    return animals;
  }

  return animals.where((animal) => animal.userId == currentUserId).toList();
});

final animalsListProvider =
    FutureProvider.autoDispose<List<AnimalEntity>>((ref) async {
  ref.watch(animalsRefreshSignalProvider);
  final animals = await ref.watch(rawAnimalsListProvider.future);
  final currentUserId = ref.watch(currentUserIdProvider);
  final scopedAnimals = currentUserId == null
      ? animals
      : animals.where((animal) => animal.userId == currentUserId).toList();
  final profile = ref.watch(profileProvider);

  if (!profile.isVeterinarian) {
    return scopedAnimals;
  }

  final managedClientState = await ref.watch(managedClientProvider.future);
  final activeClientId = managedClientState.activeClientId;

  if (activeClientId == null) {
    return const [];
  }

  return scopedAnimals.where((animal) {
    return managedClientState.animalAssignments[animal.id] == activeClientId;
  }).toList();
});

final animalByIdProvider =
    Provider.autoDispose.family<AsyncValue<AnimalEntity?>, String>((ref, id) {
  final animalsAsync = ref.watch(rawAnimalsListProvider);
  return animalsAsync.whenData(
    (animals) {
      for (final animal in animals) {
        if (animal.id == id) {
          return animal;
        }
      }

      return null;
    },
  );
});

void refreshAnimals(WidgetRef ref) {
  ref.read(animalsRefreshSignalProvider.notifier).state++;
}
