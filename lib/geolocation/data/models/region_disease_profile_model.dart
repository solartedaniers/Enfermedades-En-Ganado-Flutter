class RegionDiseaseProfileModel {
  final String climateZone;
  final String epidemiologySummary;
  final List<String> commonDiseaseKeys;

  const RegionDiseaseProfileModel({
    required this.climateZone,
    required this.epidemiologySummary,
    required this.commonDiseaseKeys,
  });
}
