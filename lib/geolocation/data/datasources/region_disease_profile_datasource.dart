import '../models/region_disease_profile_model.dart';

class RegionDiseaseProfileDatasource {
  const RegionDiseaseProfileDatasource();

  RegionDiseaseProfileModel resolveProfile({
    required String countryCode,
    required String administrativeArea,
    required String locality,
  }) {
    final normalizedCountryCode = countryCode.trim().toUpperCase();
    final normalizedAdministrativeArea = administrativeArea.trim().toLowerCase();
    final normalizedLocality = locality.trim().toLowerCase();

    if (normalizedCountryCode == 'CO') {
      if (_containsAny(normalizedAdministrativeArea, ['cundinamarca', 'boyaca']) ||
          _containsAny(normalizedLocality, ['bogota', 'tunja'])) {
        return const RegionDiseaseProfileModel(
          climateZone: 'highland temperate dairy corridor',
          epidemiologySummary:
              'Highland dairy systems often require closer vigilance for mastitis, bovine pneumonia, and moisture-related hoof or skin conditions.',
          commonDiseaseKeys: [
            'mastitis',
            'bovine_pneumonia',
            'dermatophytosis',
          ],
        );
      }

      if (_containsAny(normalizedAdministrativeArea, ['antioquia', 'caldas', 'risaralda', 'quindio'])) {
        return const RegionDiseaseProfileModel(
          climateZone: 'humid mountain livestock corridor',
          epidemiologySummary:
              'Humid mountain production areas increase the relevance of mastitis, respiratory syndromes, and gastrointestinal stress after rainfall and pasture changes.',
          commonDiseaseKeys: [
            'mastitis',
            'bovine_pneumonia',
            'gastroenteritis',
          ],
        );
      }

      if (_containsAny(normalizedAdministrativeArea, ['cordoba', 'sucre', 'magdalena', 'cesar', 'la guajira', 'atlantico', 'bolivar'])) {
        return const RegionDiseaseProfileModel(
          climateZone: 'warm tropical coastal corridor',
          epidemiologySummary:
              'Warm tropical regions require more vigilance for dehydration, enteric disease, and vesicular syndromes during outbreak alerts.',
          commonDiseaseKeys: [
            'gastroenteritis',
            'foot_and_mouth_disease',
            'dermatophytosis',
          ],
        );
      }

      if (_containsAny(normalizedAdministrativeArea, ['meta', 'casanare', 'arauca', 'vichada'])) {
        return const RegionDiseaseProfileModel(
          climateZone: 'savanna grazing plains',
          epidemiologySummary:
              'Large grazing plains make mobility, water quality, and regional outbreak surveillance especially relevant for enteric and vesicular disease patterns.',
          commonDiseaseKeys: [
            'foot_and_mouth_disease',
            'gastroenteritis',
            'bovine_pneumonia',
          ],
        );
      }

      return const RegionDiseaseProfileModel(
        climateZone: 'tropical mixed-production region',
        epidemiologySummary:
            'Mixed tropical cattle systems benefit from regional consideration of mastitis, respiratory disease, and gastrointestinal syndromes.',
        commonDiseaseKeys: [
          'mastitis',
          'bovine_pneumonia',
          'gastroenteritis',
        ],
      );
    }

    return const RegionDiseaseProfileModel(
      climateZone: 'unspecified livestock region',
      epidemiologySummary:
          'Use the geolocation as contextual evidence only and prioritize the reported symptoms and visual findings.',
      commonDiseaseKeys: [
        'mastitis',
        'bovine_pneumonia',
      ],
    );
  }

  bool _containsAny(String value, List<String> matches) {
    return matches.any(value.contains);
  }
}
