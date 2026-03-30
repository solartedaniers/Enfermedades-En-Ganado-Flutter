import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/storage_service.dart';
import '../../data/datasources/animal_local_datasource.dart';
import '../../data/datasources/animal_remote_datasource.dart';
import '../../data/repositories/animal_repository_impl.dart';
import '../../domain/usecases/add_animal.dart';
import '../../domain/usecases/get_animals.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser?.id;
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

final animalRepositoryProvider = Provider((ref) {
  return AnimalRepositoryImpl(
    localDataSource: ref.watch(animalLocalDataSourceProvider),
    remoteDataSource: ref.watch(animalRemoteDataSourceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

final addAnimalProvider = Provider((ref) {
  final animalRepository = ref.read(animalRepositoryProvider);
  return AddAnimal(animalRepository);
});

final getAnimalsProvider = Provider((ref) {
  final animalRepository = ref.read(animalRepositoryProvider);
  return GetAnimals(animalRepository);
});

final animalsListProvider = FutureProvider.autoDispose((ref) async {
  final getAnimals = ref.watch(getAnimalsProvider);
  return getAnimals();
});
