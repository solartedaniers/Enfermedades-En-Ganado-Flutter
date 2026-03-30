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
      countryCode: placemark.isoCountryCode ?? '',
      administrativeArea: placemark.administrativeArea ?? '',
      locality: placemark.locality ?? '',
    );

    return GeolocationContextModel(
      latitude: result.position.latitude,
      longitude: result.position.longitude,
      country: placemark.country ?? '',
      countryCode: placemark.isoCountryCode ?? '',
      administrativeArea: placemark.administrativeArea ?? '',
      locality: placemark.locality ?? '',
      climateZone: profile.climateZone,
      epidemiologySummary: profile.epidemiologySummary,
      commonDiseaseKeys: profile.commonDiseaseKeys,
    );
  }
}
