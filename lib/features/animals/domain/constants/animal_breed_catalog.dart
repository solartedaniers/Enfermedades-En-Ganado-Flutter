import '../../../../core/utils/app_strings.dart';

/// Catálogo de razas de animales.
/// Normaliza y muestra valores de raza de forma consistente en toda la app.
class AnimalBreedCatalog {
  AnimalBreedCatalog._();

  static const String unknownValue = 'unknown';

  /// Retorna el valor normalizado para almacenamiento en base de datos.
  /// Si el valor está vacío o es nulo, retorna [unknownValue].
  static String storageValue(String? value) {
    final normalizedValue = _normalizeValue(value);
    return normalizedValue.isEmpty ? unknownValue : normalizedValue;
  }

  /// Retorna la etiqueta de display legible para el usuario.
  /// Convierte snake_case a título capitalizado.
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

  /// Normaliza un valor de raza a snake_case minúsculas para almacenamiento.
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
