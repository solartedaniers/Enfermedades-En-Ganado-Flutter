enum AppUserType {
  farmer,
  veterinarian,
}

extension AppUserTypeX on AppUserType {
  String get storageValue =>
      this == AppUserType.veterinarian ? 'veterinarian' : 'farmer';

  String get labelKey =>
      this == AppUserType.veterinarian ? 'role_veterinarian' : 'role_farmer';

  bool get isVeterinarian => this == AppUserType.veterinarian;
}

class AppUserTypeCodec {
  static AppUserType fromValue(String? value) {
    final normalizedValue = value?.trim().toLowerCase() ?? '';

    if (normalizedValue == 'veterinarian' ||
        normalizedValue == 'veterinario') {
      return AppUserType.veterinarian;
    }

    return AppUserType.farmer;
  }

  static String fallbackStorageValue() => AppUserType.farmer.storageValue;
}
