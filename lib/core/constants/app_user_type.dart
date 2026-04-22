enum AppUserType {
  farmer,
  veterinarian,
  admin,
}

extension AppUserTypeX on AppUserType {
  String get storageValue {
    switch (this) {
      case AppUserType.farmer:
        return 'farmer';
      case AppUserType.veterinarian:
        return 'veterinarian';
      case AppUserType.admin:
        return 'admin';
    }
  }

  String get labelKey {
    switch (this) {
      case AppUserType.farmer:
        return 'role_farmer';
      case AppUserType.veterinarian:
        return 'role_veterinarian';
      case AppUserType.admin:
        return 'role_admin';
    }
  }

  bool get isVeterinarian => this == AppUserType.veterinarian;
  bool get isAdmin => this == AppUserType.admin;
}

class AppUserTypeCodec {
  static AppUserType fromValue(String? value) {
    final normalizedValue = value?.trim().toLowerCase() ?? '';

    if (normalizedValue == 'admin' || normalizedValue == 'administrador') {
      return AppUserType.admin;
    }

    if (normalizedValue == 'veterinarian' ||
        normalizedValue == 'veterinario') {
      return AppUserType.veterinarian;
    }

    return AppUserType.farmer;
  }

  static String fallbackStorageValue() => AppUserType.farmer.storageValue;
}
