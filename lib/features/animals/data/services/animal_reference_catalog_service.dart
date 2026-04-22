import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_storage_keys.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/constants/animal_breed_catalog.dart';
import '../../domain/constants/animal_constants.dart';
import '../../domain/entities/animal_breed_choice.dart';

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

  const AnimalReferenceCatalogService(this._client);

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

      final choices = (rows as List<dynamic>).map((row) {
        final data = row as Map<String, dynamic>;
        final value = (data[_valueColumn] as String?)?.trim() ?? '';
        final label = _localizedLabel(data);

        return AnimalBreedChoice(
          value: value,
          label: label,
        );
      }).where((choice) => choice.value.isNotEmpty && choice.label.isNotEmpty).toList();

      if (choices.isEmpty) {
        return await _loadCachedBreedChoices();
      }

      await _cacheBreedChoices(choices);
      return choices;
    } catch (_) {
      return _loadCachedBreedChoices();
    }
  }

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

      final options = (rows as List<dynamic>).map((row) {
        final data = row as Map<String, dynamic>;
        final months = data[_numericValueColumn] as int?;
        final label = _localizedLabel(data);

        if (months == null || months <= 0 || label.isEmpty) {
          return null;
        }

        return AnimalAgeOption(
          label: label,
          months: months,
        );
      }).whereType<AnimalAgeOption>().toList();

      if (options.isEmpty) {
        return await _loadCachedAgeOptions();
      }

      await _cacheAgeOptions(options);
      return options;
    } catch (_) {
      return _loadCachedAgeOptions();
    }
  }

  static String resolveBreedLabel(
    String? value, {
    required List<AnimalBreedChoice> choices,
  }) {
    final normalizedValue = AnimalBreedCatalog.storageValue(value);
    for (final choice in choices) {
      if (choice.value == normalizedValue) {
        return choice.label;
      }
    }

    return AnimalBreedCatalog.displayLabel(value);
  }

  String _localizedLabel(Map<String, dynamic> data) {
    final preferredLabel = AppStrings.currentLanguage == 'en'
        ? data[_labelEnColumn] as String?
        : data[_labelEsColumn] as String?;
    final fallbackLabel = AppStrings.currentLanguage == 'en'
        ? data[_labelEsColumn] as String?
        : data[_labelEnColumn] as String?;

    final resolvedLabel = (preferredLabel ?? fallbackLabel ?? '').trim();
    return _normalizeCatalogLabel(resolvedLabel);
  }

  String _normalizeCatalogLabel(String label) {
    if (label.isEmpty || AppStrings.currentLanguage != 'es') {
      return label;
    }

    return label
        .replaceAllMapped(RegExp(r'\banos\b', caseSensitive: false), (_) => 'años')
        .replaceAllMapped(RegExp(r'\bano\b', caseSensitive: false), (_) => 'año');
  }

  Future<void> _cacheBreedChoices(List<AnimalBreedChoice> choices) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = choices
        .map(
          (choice) => {
            _valueColumn: choice.value,
            'label': choice.label,
          },
        )
        .toList();
    await prefs.setString(
      AppStorageKeys.animalBreedCatalogCache,
      jsonEncode(encoded),
    );
  }

  Future<List<AnimalBreedChoice>> _loadCachedBreedChoices() async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getString(AppStorageKeys.animalBreedCatalogCache);
    if (rawValue == null || rawValue.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(rawValue) as List<dynamic>;
      final choices = decoded.map((item) {
        final data = item as Map<String, dynamic>;
        return AnimalBreedChoice(
          value: (data[_valueColumn] as String?) ?? '',
          label: (data['label'] as String?) ?? '',
        );
      }).where((choice) => choice.value.isNotEmpty && choice.label.isNotEmpty).toList();

      return choices;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _cacheAgeOptions(List<AnimalAgeOption> options) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = options
        .map(
          (option) => {
            _numericValueColumn: option.months,
            'label': option.label,
          },
        )
        .toList();
    await prefs.setString(
      AppStorageKeys.animalAgeCatalogCache,
      jsonEncode(encoded),
    );
  }

  Future<List<AnimalAgeOption>> _loadCachedAgeOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getString(AppStorageKeys.animalAgeCatalogCache);
    if (rawValue == null || rawValue.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(rawValue) as List<dynamic>;
      final options = decoded.map((item) {
        final data = item as Map<String, dynamic>;
        final months = data[_numericValueColumn] as int?;
        final label = data['label'] as String?;

        if (months == null || months <= 0 || label == null || label.isEmpty) {
          return null;
        }

        return AnimalAgeOption(
          label: label,
          months: months,
        );
      }).whereType<AnimalAgeOption>().toList();

      return options;
    } catch (_) {
      return const [];
    }
  }
}
