class AnimalConstants {
  static const String localBoxName = 'animals_box';
  static const String tableName = 'animals';
  static const String idColumn = 'id';
  static const String userIdColumn = 'user_id';
  static const String createdAtColumn = 'created_at';
  static const String profileImageUrlColumn = 'profile_image_url';
  static const int maxAgeYears = 25;

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
