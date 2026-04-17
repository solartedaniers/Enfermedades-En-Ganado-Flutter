import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/services/animal_reference_catalog_service.dart';
import '../../domain/constants/animal_constants.dart';
import '../../domain/entities/animal_breed_choice.dart';

final animalReferenceCatalogServiceProvider =
    Provider<AnimalReferenceCatalogService>(
  (ref) => AnimalReferenceCatalogService(Supabase.instance.client),
);

final animalBreedChoicesProvider =
    FutureProvider<List<AnimalBreedChoice>>((ref) async {
  ref.watch(profileProvider.select((profile) => profile.language));
  return ref.read(animalReferenceCatalogServiceProvider).fetchBreedChoices();
});

final animalAgeOptionsProvider = FutureProvider<List<AnimalAgeOption>>((ref) async {
  ref.watch(profileProvider.select((profile) => profile.language));
  return ref.read(animalReferenceCatalogServiceProvider).fetchAgeOptions();
});
