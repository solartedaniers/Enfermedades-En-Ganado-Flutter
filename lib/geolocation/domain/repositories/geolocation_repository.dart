import '../entities/geolocation_context_entity.dart';

abstract class GeolocationRepository {
  Future<GeolocationContextEntity> getCurrentContext();
}
