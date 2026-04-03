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

  static const List<String> cattleBreeds = [
    'Aberdeen Angus',
    'Beefmaster',
    'Belgian Blue',
    'Blonde d\'Aquitaine',
    'Bonsmara',
    'Brahman',
    'Brangus',
    'Brown Swiss',
    'Charolais',
    'Chianina',
    'Criollo',
    'Devon',
    'Droughtmaster',
    'Fleckvieh',
    'Gelbvieh',
    'Gir',
    'Guzera',
    'Hereford',
    'Holstein Friesian',
    'Jersey',
    'Limousin',
    'Longhorn',
    'Maine-Anjou',
    'Marchigiana',
    'Montbeliarde',
    'Murray Grey',
    'Nelore',
    'Normande',
    'Piedmontese',
    'Pinzgauer',
    'Red Angus',
    'Red Poll',
    'Romosinuano',
    'Sahiwal',
    'Salorn',
    'Santa Gertrudis',
    'Senepol',
    'Shorthorn',
    'Simmental',
    'Taurus',
    'Zebu (Cebu)',
  ];
}

class AnimalAgeOption {
  final String label;
  final int months;

  const AnimalAgeOption({
    required this.label,
    required this.months,
  });
}
