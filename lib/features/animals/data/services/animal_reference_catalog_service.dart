import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/app_strings.dart';
import '../../domain/constants/animal_breed_catalog.dart';
import '../../domain/constants/animal_constants.dart';
import '../../domain/entities/animal_breed_choice.dart';
import 'animal_catalog_cache_service.dart';

/// Servicio de catálogo de referencia de animales.
/// Responsabilidad única: obtener datos de catálogo desde Supabase con fallback a caché.
class AnimalReferenceCatalogService {
  static const String _tableName = 'animal_reference_options';
  static const String _categoryColumn = 'category';
  static const String _valueColumn = 'value';
  static const String _labelEsColumn = 'label_es';
  static const String _labelEnColumn = 'label_en';
  static const String _numericValueColumn = 'numeric_value';
  static const String _sortOrderColumn = 'sort_order';
  static const String _isActiveColumn = 'is_active';

  final SupabaseClient _client;
  final AnimalCatalogCacheService _cacheService;

  const AnimalReferenceCatalogService(this._client, this._cacheService);

  /// Obtiene las opciones de raza, con fallback a caché si no hay conexión.
  Future<List<AnimalBreedChoice>> fetchBreedChoices() async {
    try {
      final rows = await _client
          .from(_tableName)
          .select(
            '$_valueColumn, $_labelEsColumn, $_labelEnColumn, $_sortOrderColumn',
          )
          .eq(_categoryColumn, 'breed')
          .eq(_isActiveColumn, true)
          .order(_sortOrderColumn)
          .order(_valueColumn);

      final choices = (rows as List<dynamic>)
          .map((row) {
            final data = row as Map<String, dynamic>;
            final value = (data[_valueColumn] as String?)?.trim() ?? '';
            final label = _localizedLabel(data);
            return AnimalBreedChoice(value: value, label: label);
          })
          .where((c) => c.value.isNotEmpty && c.label.isNotEmpty)
          .toList();

      if (choices.isEmpty) return _cacheService.loadBreedChoices();

      await _cacheService.saveBreedChoices(choices);
      return choices;
    } catch (_) {
      return _cacheService.loadBreedChoices();
    }
  }

  /// Obtiene las opciones de edad, con fallback a caché si no hay conexión.
  Future<List<AnimalAgeOption>> fetchAgeOptions() async {
    try {
      final rows = await _client
          .from(_tableName)
          .select(
            '$_labelEsColumn, $_labelEnColumn, $_numericValueColumn, $_sortOrderColumn',
          )
          .eq(_categoryColumn, 'age')
          .eq(_isActiveColumn, true)
          .order(_sortOrderColumn)
          .order(_numericValueColumn);

      final options = (rows as List<dynamic>)
          .map((row) {
            final data = row as Map<String, dynamic>;
            final months = data[_numericValueColumn] as int?;
            final label = _localizedLabel(data);
            if (months == null || months <= 0 || label.isEmpty) return null;
            return AnimalAgeOption(label: label, months: months);
          })
          .whereType<AnimalAgeOption>()
          .toList();

      if (options.isEmpty) return _cacheService.loadAgeOptions();

      await _cacheService.saveAgeOptions(options);
      return options;
    } catch (_) {
      return _cacheService.loadAgeOptions();
    }
  }

  /// Resuelve la etiqueta de raza a partir de su valor y la lista de opciones disponibles.
  static String resolveBreedLabel(
    String? value, {
    required List<AnimalBreedChoice> choices,
  }) {
    final normalizedValue = AnimalBreedCatalog.storageValue(value);
    for (final choice in choices) {
      if (choice.value == normalizedValue) return choice.label;
    }
    return AnimalBreedCatalog.displayLabel(value);
  }

  /// Retorna la etiqueta localizada según el idioma activo de la app.
  String _localizedLabel(Map<String, dynamic> data) {
    final preferredLabel = AppStrings.currentLanguage == 'en'
        ? data[_labelEnColumn] as String?
        : data[_labelEsColumn] as String?;
    final fallbackLabel = AppStrings.currentLanguage == 'en'
        ? data[_labelEsColumn] as String?
        : data[_labelEnColumn] as String?;

    final resolved = (preferredLabel ?? fallbackLabel ?? '').trim();
    return _normalizeCatalogLabel(resolved);
  }

  /// Corrige caracteres especiales del español en etiquetas del catálogo.
  String _normalizeCatalogLabel(String label) {
    if (label.isEmpty || AppStrings.currentLanguage != 'es') return label;
    return label
        .replaceAllMapped(RegExp(r'\banos\b', caseSensitive: false), (_) => 'años')
        .replaceAllMapped(RegExp(r'\bano\b', caseSensitive: false), (_) => 'año');
  }
}
