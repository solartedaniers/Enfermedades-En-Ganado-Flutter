import '../../config/app_location_settings.dart';
import '../../domain/entities/geolocation_context_entity.dart';
import '../../domain/repositories/geolocation_repository.dart';
import '../datasources/device_geolocation_datasource.dart';
import '../datasources/region_disease_profile_datasource.dart';
import '../models/geolocation_context_model.dart';

class GeolocationRepositoryImpl implements GeolocationRepository {
  final DeviceGeolocationDatasource deviceDatasource;
  final RegionDiseaseProfileDatasource regionProfileDatasource;

  const GeolocationRepositoryImpl({
    required this.deviceDatasource,
    required this.regionProfileDatasource,
  });

  @override
  Future<GeolocationContextEntity> getCurrentContext() async {
    final result = await deviceDatasource.getCurrentLocation();
    final placemark = result.placemark;
    final profile = regionProfileDatasource.resolveProfile(
      countryCode: placemark.isoCountryCode ?? AppLocationSettings.emptyValue,
      administrativeArea:
          placemark.administrativeArea ?? AppLocationSettings.emptyValue,
      locality: placemark.locality ?? AppLocationSettings.emptyValue,
    );

    return GeolocationContextModel(
      latitude: result.position.latitude,
      longitude: result.position.longitude,
      country: placemark.country ?? AppLocationSettings.emptyValue,
      countryCode: placemark.isoCountryCode ?? AppLocationSettings.emptyValue,
      administrativeArea:
          placemark.administrativeArea ?? AppLocationSettings.emptyValue,
      locality: placemark.locality ?? AppLocationSettings.emptyValue,
      climateZone: profile.climateZone,
      epidemiologySummary: profile.epidemiologySummary,
      commonDiseaseKeys: profile.commonDiseaseKeys,
    );
  }
}
