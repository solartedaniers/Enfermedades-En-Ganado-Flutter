import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/utils/app_strings.dart';

class DeviceGeolocationResult {
  final Position position;
  final Placemark placemark;

  const DeviceGeolocationResult({
    required this.position,
    required this.placemark,
  });
}

class DeviceGeolocationDatasource {
  const DeviceGeolocationDatasource();

  Future<DeviceGeolocationResult> getCurrentLocation() async {
    final servicesEnabled = await Geolocator.isLocationServiceEnabled();
    if (!servicesEnabled) {
      throw Exception(AppStrings.t('geolocation_services_disabled'));
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(AppStrings.t('geolocation_permission_denied'));
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(AppStrings.t('geolocation_permission_denied_forever'));
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    return DeviceGeolocationResult(
      position: position,
      placemark: placemarks.isNotEmpty ? placemarks.first : const Placemark(),
    );
  }
}
