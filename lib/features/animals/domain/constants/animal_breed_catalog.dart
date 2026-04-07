import '../../../../core/utils/app_strings.dart';

class AnimalBreedOption {
  final String value;
  final String labelKey;
  final List<String> legacyValues;

  const AnimalBreedOption({
    required this.value,
    required this.labelKey,
    this.legacyValues = const [],
  });
}

class AnimalBreedCatalog {
  static const String unknownValue = 'unknown';

  static const List<AnimalBreedOption> cattleBreeds = [
    AnimalBreedOption(
      value: 'aberdeen_angus',
      labelKey: 'breed_aberdeen_angus',
      legacyValues: ['Aberdeen Angus'],
    ),
    AnimalBreedOption(
      value: 'beefmaster',
      labelKey: 'breed_beefmaster',
      legacyValues: ['Beefmaster'],
    ),
    AnimalBreedOption(
      value: 'belgian_blue',
      labelKey: 'breed_belgian_blue',
      legacyValues: ['Belgian Blue'],
    ),
    AnimalBreedOption(
      value: 'blonde_d_aquitaine',
      labelKey: 'breed_blonde_d_aquitaine',
      legacyValues: ['Blonde d\'Aquitaine'],
    ),
    AnimalBreedOption(
      value: 'bonsmara',
      labelKey: 'breed_bonsmara',
      legacyValues: ['Bonsmara'],
    ),
    AnimalBreedOption(
      value: 'brahman',
      labelKey: 'breed_brahman',
      legacyValues: ['Brahman'],
    ),
    AnimalBreedOption(
      value: 'brangus',
      labelKey: 'breed_brangus',
      legacyValues: ['Brangus'],
    ),
    AnimalBreedOption(
      value: 'brown_swiss',
      labelKey: 'breed_brown_swiss',
      legacyValues: ['Brown Swiss'],
    ),
    AnimalBreedOption(
      value: 'charolais',
      labelKey: 'breed_charolais',
      legacyValues: ['Charolais'],
    ),
    AnimalBreedOption(
      value: 'chianina',
      labelKey: 'breed_chianina',
      legacyValues: ['Chianina'],
    ),
    AnimalBreedOption(
      value: 'criollo',
      labelKey: 'breed_criollo',
      legacyValues: ['Criollo'],
    ),
    AnimalBreedOption(
      value: 'devon',
      labelKey: 'breed_devon',
      legacyValues: ['Devon'],
    ),
    AnimalBreedOption(
      value: 'droughtmaster',
      labelKey: 'breed_droughtmaster',
      legacyValues: ['Droughtmaster'],
    ),
    AnimalBreedOption(
      value: 'fleckvieh',
      labelKey: 'breed_fleckvieh',
      legacyValues: ['Fleckvieh'],
    ),
    AnimalBreedOption(
      value: 'gelbvieh',
      labelKey: 'breed_gelbvieh',
      legacyValues: ['Gelbvieh'],
    ),
    AnimalBreedOption(
      value: 'gir',
      labelKey: 'breed_gir',
      legacyValues: ['Gir'],
    ),
    AnimalBreedOption(
      value: 'guzera',
      labelKey: 'breed_guzera',
      legacyValues: ['Guzera'],
    ),
    AnimalBreedOption(
      value: 'hereford',
      labelKey: 'breed_hereford',
      legacyValues: ['Hereford'],
    ),
    AnimalBreedOption(
      value: 'holstein_friesian',
      labelKey: 'breed_holstein_friesian',
      legacyValues: ['Holstein Friesian'],
    ),
    AnimalBreedOption(
      value: 'jersey',
      labelKey: 'breed_jersey',
      legacyValues: ['Jersey'],
    ),
    AnimalBreedOption(
      value: 'limousin',
      labelKey: 'breed_limousin',
      legacyValues: ['Limousin'],
    ),
    AnimalBreedOption(
      value: 'longhorn',
      labelKey: 'breed_longhorn',
      legacyValues: ['Longhorn'],
    ),
    AnimalBreedOption(
      value: 'maine_anjou',
      labelKey: 'breed_maine_anjou',
      legacyValues: ['Maine-Anjou'],
    ),
    AnimalBreedOption(
      value: 'marchigiana',
      labelKey: 'breed_marchigiana',
      legacyValues: ['Marchigiana'],
    ),
    AnimalBreedOption(
      value: 'montbeliarde',
      labelKey: 'breed_montbeliarde',
      legacyValues: ['Montbeliarde'],
    ),
    AnimalBreedOption(
      value: 'murray_grey',
      labelKey: 'breed_murray_grey',
      legacyValues: ['Murray Grey'],
    ),
    AnimalBreedOption(
      value: 'nelore',
      labelKey: 'breed_nelore',
      legacyValues: ['Nelore'],
    ),
    AnimalBreedOption(
      value: 'normande',
      labelKey: 'breed_normande',
      legacyValues: ['Normande'],
    ),
    AnimalBreedOption(
      value: 'piedmontese',
      labelKey: 'breed_piedmontese',
      legacyValues: ['Piedmontese'],
    ),
    AnimalBreedOption(
      value: 'pinzgauer',
      labelKey: 'breed_pinzgauer',
      legacyValues: ['Pinzgauer'],
    ),
    AnimalBreedOption(
      value: 'red_angus',
      labelKey: 'breed_red_angus',
      legacyValues: ['Red Angus'],
    ),
    AnimalBreedOption(
      value: 'red_poll',
      labelKey: 'breed_red_poll',
      legacyValues: ['Red Poll'],
    ),
    AnimalBreedOption(
      value: 'romosinuano',
      labelKey: 'breed_romosinuano',
      legacyValues: ['Romosinuano'],
    ),
    AnimalBreedOption(
      value: 'sahiwal',
      labelKey: 'breed_sahiwal',
      legacyValues: ['Sahiwal'],
    ),
    AnimalBreedOption(
      value: 'salorn',
      labelKey: 'breed_salorn',
      legacyValues: ['Salorn'],
    ),
    AnimalBreedOption(
      value: 'santa_gertrudis',
      labelKey: 'breed_santa_gertrudis',
      legacyValues: ['Santa Gertrudis'],
    ),
    AnimalBreedOption(
      value: 'senepol',
      labelKey: 'breed_senepol',
      legacyValues: ['Senepol'],
    ),
    AnimalBreedOption(
      value: 'shorthorn',
      labelKey: 'breed_shorthorn',
      legacyValues: ['Shorthorn'],
    ),
    AnimalBreedOption(
      value: 'simmental',
      labelKey: 'breed_simmental',
      legacyValues: ['Simmental'],
    ),
    AnimalBreedOption(
      value: 'taurus',
      labelKey: 'breed_taurus',
      legacyValues: ['Taurus'],
    ),
    AnimalBreedOption(
      value: 'zebu_cebu',
      labelKey: 'breed_zebu_cebu',
      legacyValues: ['Zebu (Cebu)'],
    ),
  ];

  static const AnimalBreedOption _unknown = AnimalBreedOption(
    value: unknownValue,
    labelKey: 'animal_unknown_breed',
  );

  static AnimalBreedOption fromValue(String? value) {
    final normalizedValue = _normalizeValue(value);
    if (normalizedValue.isEmpty) {
      return _unknown;
    }

    for (final breed in cattleBreeds) {
      if (breed.value == normalizedValue) {
        return breed;
      }

      if (breed.legacyValues.any(
        (legacyValue) => _normalizeValue(legacyValue) == normalizedValue,
      )) {
        return breed;
      }
    }

    if (normalizedValue == unknownValue) {
      return _unknown;
    }

    return AnimalBreedOption(
      value: normalizedValue,
      labelKey: 'animal_unknown_breed',
    );
  }

  static List<AnimalBreedOption> options() => cattleBreeds;

  static String storageValue(String? value) => fromValue(value).value;

  static String displayLabel(String? value) {
    final option = fromValue(value);
    if (option.labelKey == 'animal_unknown_breed' && option.value != unknownValue) {
      return value?.trim().isNotEmpty == true
          ? value!.trim()
          : AppStrings.t(option.labelKey);
    }

    return AppStrings.t(option.labelKey);
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
