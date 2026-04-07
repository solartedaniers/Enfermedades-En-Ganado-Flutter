import 'region_disease_profile_model.dart';

class RegionDiseaseProfilesConfigModel {
  final RegionDiseaseProfileModel defaultProfile;
  final Map<String, CountryRegionProfileConfigModel> countries;

  const RegionDiseaseProfilesConfigModel({
    required this.defaultProfile,
    required this.countries,
  });

  factory RegionDiseaseProfilesConfigModel.fromJson(Map<String, dynamic> json) {
    final countriesJson = json['countries'] as Map<String, dynamic>? ?? {};

    return RegionDiseaseProfilesConfigModel(
      defaultProfile: RegionDiseaseProfileModel.fromJson(
        json['default_profile'] as Map<String, dynamic>? ?? const {},
      ),
      countries: {
        for (final entry in countriesJson.entries)
          entry.key: CountryRegionProfileConfigModel.fromJson(
            entry.value as Map<String, dynamic>? ?? const {},
          ),
      },
    );
  }
}

class CountryRegionProfileConfigModel {
  final RegionDiseaseProfileModel fallbackProfile;
  final List<RegionProfileRuleModel> rules;

  const CountryRegionProfileConfigModel({
    required this.fallbackProfile,
    required this.rules,
  });

  factory CountryRegionProfileConfigModel.fromJson(Map<String, dynamic> json) {
    final rulesJson = json['rules'] as List<dynamic>? ?? const [];

    return CountryRegionProfileConfigModel(
      fallbackProfile: RegionDiseaseProfileModel.fromJson(
        json['fallback_profile'] as Map<String, dynamic>? ?? const {},
      ),
      rules: rulesJson
          .map(
            (item) => RegionProfileRuleModel.fromJson(
              item as Map<String, dynamic>? ?? const {},
            ),
          )
          .toList(),
    );
  }
}

class RegionProfileRuleModel {
  final List<String> administrativeAreas;
  final List<String> localities;
  final RegionDiseaseProfileModel profile;

  const RegionProfileRuleModel({
    required this.administrativeAreas,
    required this.localities,
    required this.profile,
  });

  factory RegionProfileRuleModel.fromJson(Map<String, dynamic> json) {
    return RegionProfileRuleModel(
      administrativeAreas: ((json['administrative_areas'] as List<dynamic>?) ??
              const [])
          .map((item) => item.toString().trim().toLowerCase())
          .toList(),
      localities: ((json['localities'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString().trim().toLowerCase())
          .toList(),
      profile: RegionDiseaseProfileModel.fromJson(
        json['profile'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  bool matches({
    required String administrativeArea,
    required String locality,
  }) {
    return _containsAny(administrativeArea, administrativeAreas) ||
        _containsAny(locality, localities);
  }

  bool _containsAny(String value, List<String> matches) {
    return matches.any(value.contains);
  }
}
