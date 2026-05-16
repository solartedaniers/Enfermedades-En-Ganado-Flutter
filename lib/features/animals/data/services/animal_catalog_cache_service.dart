import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_storage_keys.dart';
import '../../domain/constants/animal_constants.dart';
import '../../domain/entities/animal_breed_choice.dart';

/// Servicio de caché local para el catálogo de referencia de animales.
/// Responsabilidad única: persistir y recuperar opciones de catálogo en SharedPreferences.
class AnimalCatalogCacheService {
  static const String _valueKey = 'value';
  static const String _labelKey = 'label';
  static const String _monthsKey = 'numeric_value';

  /// Persiste la lista de razas en SharedPreferences.
  Future<void> saveBreedChoices(List<AnimalBreedChoice> choices) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = choices
        .map((choice) => {_valueKey: choice.value, _labelKey: choice.label})
        .toList();
    await prefs.setString(
      AppStorageKeys.animalBreedCatalogCache,
      jsonEncode(encoded),
    );
  }

  /// Recupera la lista de razas desde SharedPreferences.
  Future<List<AnimalBreedChoice>> loadBreedChoices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppStorageKeys.animalBreedCatalogCache);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) {
            final data = item as Map<String, dynamic>;
            return AnimalBreedChoice(
              value: (data[_valueKey] as String?) ?? '',
              label: (data[_labelKey] as String?) ?? '',
            );
          })
          .where((c) => c.value.isNotEmpty && c.label.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Persiste la lista de opciones de edad en SharedPreferences.
  Future<void> saveAgeOptions(List<AnimalAgeOption> options) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = options
        .map((option) => {_monthsKey: option.months, _labelKey: option.label})
        .toList();
    await prefs.setString(
      AppStorageKeys.animalAgeCatalogCache,
      jsonEncode(encoded),
    );
  }

  /// Recupera la lista de opciones de edad desde SharedPreferences.
  Future<List<AnimalAgeOption>> loadAgeOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppStorageKeys.animalAgeCatalogCache);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) {
            final data = item as Map<String, dynamic>;
            final months = data[_monthsKey] as int?;
            final label = data[_labelKey] as String?;
            if (months == null || months <= 0 || label == null || label.isEmpty) {
              return null;
            }
            return AnimalAgeOption(label: label, months: months);
          })
          .whereType<AnimalAgeOption>()
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
