import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/constants/app_asset_paths.dart';
import '../models/region_disease_profile_model.dart';
import '../models/region_disease_profiles_config_model.dart';

class RegionDiseaseProfileDatasource {
  const RegionDiseaseProfileDatasource();

  static RegionDiseaseProfilesConfigModel? _cachedConfig;

  Future<RegionDiseaseProfileModel> resolveProfile({
    required String countryCode,
    required String administrativeArea,
    required String locality,
  }) async {
    final config = await _loadConfig();
    final normalizedCountryCode = countryCode.trim().toUpperCase();
    final normalizedAdministrativeArea = administrativeArea.trim().toLowerCase();
    final normalizedLocality = locality.trim().toLowerCase();
    final countryConfig = config.countries[normalizedCountryCode];

    if (countryConfig == null) {
      return config.defaultProfile;
    }

    for (final rule in countryConfig.rules) {
      if (rule.matches(
        administrativeArea: normalizedAdministrativeArea,
        locality: normalizedLocality,
      )) {
        return rule.profile;
      }
    }

    return countryConfig.fallbackProfile;
  }

  Future<RegionDiseaseProfilesConfigModel> _loadConfig() async {
    final cachedConfig = _cachedConfig;
    if (cachedConfig != null) {
      return cachedConfig;
    }

    final rawJson = await rootBundle.loadString(
      AppAssetPaths.regionDiseaseProfiles,
    );
    final decodedJson = jsonDecode(rawJson) as Map<String, dynamic>;
    final parsedConfig = RegionDiseaseProfilesConfigModel.fromJson(decodedJson);
    _cachedConfig = parsedConfig;
    return parsedConfig;
  }
}
