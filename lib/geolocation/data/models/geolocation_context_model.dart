import '../../domain/entities/geolocation_context_entity.dart';

class GeolocationContextModel extends GeolocationContextEntity {
  const GeolocationContextModel({
    required super.latitude,
    required super.longitude,
    required super.country,
    required super.countryCode,
    required super.administrativeArea,
    required super.locality,
    required super.climateZone,
    required super.epidemiologySummary,
    required super.commonDiseaseKeys,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'country_code': countryCode,
      'administrative_area': administrativeArea,
      'locality': locality,
      'climate_zone': climateZone,
      'epidemiology_summary': epidemiologySummary,
      'common_disease_keys': commonDiseaseKeys,
    };
  }
}
