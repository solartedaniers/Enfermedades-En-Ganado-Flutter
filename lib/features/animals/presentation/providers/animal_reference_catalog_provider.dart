import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/services/animal_catalog_cache_service.dart';
import '../../data/services/animal_reference_catalog_service.dart';
import '../../domain/constants/animal_constants.dart';
import '../../domain/entities/animal_breed_choice.dart';

/// Proveedor del servicio de caché del catálogo.
final animalCatalogCacheServiceProvider = Provider<AnimalCatalogCacheService>(
  (ref) => AnimalCatalogCacheService(),
);

/// Proveedor del servicio de catálogo de referencia de animales.
final animalReferenceCatalogServiceProvider =
    Provider<AnimalReferenceCatalogService>(
  (ref) => AnimalReferenceCatalogService(
    Supabase.instance.client,
    ref.watch(animalCatalogCacheServiceProvider),
  ),
);

/// Lista de opciones de raza disponibles.
/// Se recarga automáticamente al cambiar de idioma.
final animalBreedChoicesProvider =
    FutureProvider<List<AnimalBreedChoice>>((ref) async {
  ref.watch(profileProvider.select((p) => p.language));
  return ref.read(animalReferenceCatalogServiceProvider).fetchBreedChoices();
});

/// Lista de opciones de edad disponibles.
/// Se recarga automáticamente al cambiar de idioma.
final animalAgeOptionsProvider =
    FutureProvider<List<AnimalAgeOption>>((ref) async {
  ref.watch(profileProvider.select((p) => p.language));
  return ref.read(animalReferenceCatalogServiceProvider).fetchAgeOptions();
});
