enum AppAccountStatus {
  active,
  suspended,
  deleted,
}

extension AppAccountStatusX on AppAccountStatus {
  String get storageValue {
    switch (this) {
      case AppAccountStatus.active:
        return 'active';
      case AppAccountStatus.suspended:
        return 'suspended';
      case AppAccountStatus.deleted:
        return 'deleted';
    }
  }

  String get labelKey {
    switch (this) {
      case AppAccountStatus.active:
        return 'account_status_active';
      case AppAccountStatus.suspended:
        return 'account_status_suspended';
      case AppAccountStatus.deleted:
        return 'account_status_deleted';
    }
  }

  bool get isActive => this == AppAccountStatus.active;
}

class AppAccountStatusCodec {
  static AppAccountStatus fromValue(String? value) {
    final normalizedValue = value?.trim().toLowerCase() ?? '';

    switch (normalizedValue) {
      case 'suspended':
      case 'suspendido':
        return AppAccountStatus.suspended;
      case 'deleted':
      case 'eliminado':
        return AppAccountStatus.deleted;
      default:
        return AppAccountStatus.active;
    }
  }
}
