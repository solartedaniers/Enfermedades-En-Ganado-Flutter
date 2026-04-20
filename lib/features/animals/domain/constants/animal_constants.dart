import '../../../../core/constants/app_storage_keys.dart';

class AnimalConstants {
  static const String localBoxName = AppStorageKeys.animalsBox;
  static const String tableName = AppStorageKeys.animalsTable;
  static const String idColumn = AppStorageKeys.animalIdColumn;
  static const String userIdColumn = AppStorageKeys.animalUserIdColumn;
  static const String createdAtColumn = AppStorageKeys.animalCreatedAtColumn;
  static const String profileImageUrlColumn =
      AppStorageKeys.animalProfileImageUrlColumn;
  static const int maxAgeYears = 25;
  static const String cattleSpecies = 'bovine';
  static const String livestockAssetPath = 'lib/images/animals.webp';
}

class AnimalAgeOption {
  final String label;
  final int months;

  const AnimalAgeOption({
    required this.label,
    required this.months,
  });
}
