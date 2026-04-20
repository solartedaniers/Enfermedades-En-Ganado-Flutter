import '../entities/geolocation_context_entity.dart';
import '../repositories/geolocation_repository.dart';

class GetCurrentGeolocationContext {
  final GeolocationRepository repository;

  const GetCurrentGeolocationContext(this.repository);

  Future<GeolocationContextEntity> call() {
    return repository.getCurrentContext();
  }
}
