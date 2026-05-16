import '../../../../core/constants/app_storage_keys.dart';

/// Constantes del dominio de animales.
/// Centraliza nombres de tablas, columnas y valores fijos del módulo.
class AnimalConstants {
  AnimalConstants._();

  // --- Almacenamiento local ---
  static const String localBoxName = AppStorageKeys.animalsBox;

  // --- Tabla remota ---
  static const String tableName = AppStorageKeys.animalsTable;
  static const String idColumn = AppStorageKeys.animalIdColumn;
  static const String userIdColumn = AppStorageKeys.animalUserIdColumn;
  static const String createdAtColumn = AppStorageKeys.animalCreatedAtColumn;
  static const String profileImageUrlColumn =
      AppStorageKeys.animalProfileImageUrlColumn;

  // --- Reglas de dominio ---
  static const int maxAgeYears = 25;
  static const String cattleSpecies = 'bovine';

  // --- Assets ---
  // Valor centralizado en AppAssetPaths.animalDefaultImage
  static const String livestockAssetPath = 'lib/images/animals.webp';
}

/// Opción de edad del animal con etiqueta localizada y valor en meses.
class AnimalAgeOption {
  final String label;
  final int months;

  const AnimalAgeOption({
    required this.label,
    required this.months,
  });
}