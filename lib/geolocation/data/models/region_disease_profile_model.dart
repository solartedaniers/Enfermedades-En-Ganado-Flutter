import '../../../core/utils/json_parser.dart';

class RegionDiseaseProfileModel {
  final String climateZoneKey;
  final String epidemiologySummaryKey;
  final List<String> commonDiseaseKeys;

  const RegionDiseaseProfileModel({
    required this.climateZoneKey,
    required this.epidemiologySummaryKey,
    required this.commonDiseaseKeys,
  });

  factory RegionDiseaseProfileModel.fromJson(Map<String, dynamic> json) {
    return RegionDiseaseProfileModel(
      climateZoneKey: JsonParser.asString(json['climate_zone_key']) ?? '',
      epidemiologySummaryKey:
          JsonParser.asString(json['epidemiology_summary_key']) ?? '',
      commonDiseaseKeys: JsonParser.asStringList(json['common_disease_keys']),
    );
  }
}
