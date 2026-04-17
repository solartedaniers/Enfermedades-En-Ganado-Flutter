import '../../../../core/utils/app_strings.dart';

class AnimalBreedCatalog {
  static const String unknownValue = 'unknown';

  static String storageValue(String? value) {
    final normalizedValue = _normalizeValue(value);
    return normalizedValue.isEmpty ? unknownValue : normalizedValue;
  }

  static String displayLabel(String? value) {
    final normalizedValue = storageValue(value);
    if (normalizedValue == unknownValue) {
      return AppStrings.t('animal_unknown_breed');
    }

    return normalizedValue
        .split('_')
        .where((segment) => segment.isNotEmpty)
        .map((segment) {
          final lowerSegment = segment.toLowerCase();
          return '${lowerSegment[0].toUpperCase()}${lowerSegment.substring(1)}';
        })
        .join(' ');
  }

  static String _normalizeValue(String? value) {
    return value
            ?.trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .replaceAll(RegExp(r'^_|_$'), '') ??
        '';
  }
}
