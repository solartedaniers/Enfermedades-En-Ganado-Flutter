import '../models/region_disease_profile_model.dart';

class RegionDiseaseProfileDatasource {
  const RegionDiseaseProfileDatasource();

  static const RegionDiseaseProfileModel _defaultProfile =
      RegionDiseaseProfileModel(
        climateZone: 'unspecified livestock region',
        epidemiologySummary:
            'Use the geolocation as contextual evidence only and prioritize the reported symptoms and visual findings.',
        commonDiseaseKeys: [
          'mastitis',
          'bovine_pneumonia',
        ],
      );

  static const RegionDiseaseProfileModel _highlandDairyProfile =
      RegionDiseaseProfileModel(
        climateZone: 'highland temperate dairy corridor',
        epidemiologySummary:
            'Highland dairy systems often require closer vigilance for mastitis, bovine pneumonia, and moisture-related hoof or skin conditions.',
        commonDiseaseKeys: [
          'mastitis',
          'bovine_pneumonia',
          'dermatophytosis',
        ],
      );

  static const RegionDiseaseProfileModel _humidMountainProfile =
      RegionDiseaseProfileModel(
        climateZone: 'humid mountain livestock corridor',
        epidemiologySummary:
            'Humid mountain production areas increase the relevance of mastitis, respiratory syndromes, and gastrointestinal stress after rainfall and pasture changes.',
        commonDiseaseKeys: [
          'mastitis',
          'bovine_pneumonia',
          'gastroenteritis',
        ],
      );

  static const RegionDiseaseProfileModel _warmCoastalProfile =
      RegionDiseaseProfileModel(
        climateZone: 'warm tropical coastal corridor',
        epidemiologySummary:
            'Warm tropical regions require more vigilance for dehydration, enteric disease, and vesicular syndromes during outbreak alerts.',
        commonDiseaseKeys: [
          'gastroenteritis',
          'foot_and_mouth_disease',
          'dermatophytosis',
        ],
      );

  static const RegionDiseaseProfileModel _savannaProfile =
      RegionDiseaseProfileModel(
        climateZone: 'savanna grazing plains',
        epidemiologySummary:
            'Large grazing plains make mobility, water quality, and regional outbreak surveillance especially relevant for enteric and vesicular disease patterns.',
        commonDiseaseKeys: [
          'foot_and_mouth_disease',
          'gastroenteritis',
          'bovine_pneumonia',
        ],
      );

  static const RegionDiseaseProfileModel _colombiaFallbackProfile =
      RegionDiseaseProfileModel(
        climateZone: 'tropical mixed-production region',
        epidemiologySummary:
            'Mixed tropical cattle systems benefit from regional consideration of mastitis, respiratory disease, and gastrointestinal syndromes.',
        commonDiseaseKeys: [
          'mastitis',
          'bovine_pneumonia',
          'gastroenteritis',
        ],
      );

  static const List<_RegionProfileRule> _colombiaRules = [
    _RegionProfileRule(
      administrativeAreas: ['cundinamarca', 'boyaca'],
      localities: ['bogota', 'tunja'],
      profile: _highlandDairyProfile,
    ),
    _RegionProfileRule(
      administrativeAreas: ['antioquia', 'caldas', 'risaralda', 'quindio'],
      profile: _humidMountainProfile,
    ),
    _RegionProfileRule(
      administrativeAreas: [
        'cordoba',
        'sucre',
        'magdalena',
        'cesar',
        'la guajira',
        'atlantico',
        'bolivar',
      ],
      profile: _warmCoastalProfile,
    ),
    _RegionProfileRule(
      administrativeAreas: ['meta', 'casanare', 'arauca', 'vichada'],
      profile: _savannaProfile,
    ),
  ];

  RegionDiseaseProfileModel resolveProfile({
    required String countryCode,
    required String administrativeArea,
    required String locality,
  }) {
    final normalizedCountryCode = countryCode.trim().toUpperCase();
    final normalizedAdministrativeArea = administrativeArea.trim().toLowerCase();
    final normalizedLocality = locality.trim().toLowerCase();

    if (normalizedCountryCode != 'CO') {
      return _defaultProfile;
    }

    for (final rule in _colombiaRules) {
      if (rule.matches(
        administrativeArea: normalizedAdministrativeArea,
        locality: normalizedLocality,
      )) {
        return rule.profile;
      }
    }

    return _colombiaFallbackProfile;
  }
}

class _RegionProfileRule {
  final List<String> administrativeAreas;
  final List<String> localities;
  final RegionDiseaseProfileModel profile;

  const _RegionProfileRule({
    this.administrativeAreas = const [],
    this.localities = const [],
    required this.profile,
  });

  bool matches({
    required String administrativeArea,
    required String locality,
  }) {
    return _containsAny(administrativeArea, administrativeAreas) ||
        _containsAny(locality, localities);
  }

  bool _containsAny(String value, List<String> matches) {
    return matches.any(value.contains);
  }
}
