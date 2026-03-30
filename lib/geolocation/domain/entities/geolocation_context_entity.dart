class GeolocationContextEntity {
  final double latitude;
  final double longitude;
  final String country;
  final String countryCode;
  final String administrativeArea;
  final String locality;
  final String climateZone;
  final String epidemiologySummary;
  final List<String> commonDiseaseKeys;

  const GeolocationContextEntity({
    required this.latitude,
    required this.longitude,
    required this.country,
    required this.countryCode,
    required this.administrativeArea,
    required this.locality,
    required this.climateZone,
    required this.epidemiologySummary,
    required this.commonDiseaseKeys,
  });

  String get regionLabel {
    final segments = [
      locality,
      administrativeArea,
      country,
    ].where((item) => item.trim().isNotEmpty).toList();

    return segments.join(', ');
  }
}
