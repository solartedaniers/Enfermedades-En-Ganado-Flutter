import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class AppLocationSettings {
  static const currentLocation = LocationSettings(
    accuracy: LocationAccuracy.high,
  );

  static const Placemark emptyPlacemark = Placemark();
  static const String colombiaCountryCode = 'CO';
  static const String emptyValue = '';
}
