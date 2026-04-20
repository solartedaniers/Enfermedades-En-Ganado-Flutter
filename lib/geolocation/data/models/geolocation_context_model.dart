import '../../../core/constants/app_json_keys.dart';
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
      AppJsonKeys.latitude: latitude,
      AppJsonKeys.longitude: longitude,
      AppJsonKeys.country: country,
      AppJsonKeys.countryCode: countryCode,
      AppJsonKeys.administrativeArea: administrativeArea,
      AppJsonKeys.locality: locality,
      AppJsonKeys.climateZone: climateZone,
      AppJsonKeys.epidemiologySummary: epidemiologySummary,
      AppJsonKeys.commonDiseaseKeys: commonDiseaseKeys,
    };
  }
}
