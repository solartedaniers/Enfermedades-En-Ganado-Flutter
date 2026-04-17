class AppStorageKeys {
  static const String animalsBox = 'animals_box';
  static const String animalsTable = 'animals';
  static const String animalIdColumn = 'id';
  static const String animalUserIdColumn = 'user_id';
  static const String animalCreatedAtColumn = 'created_at';
  static const String animalProfileImageUrlColumn = 'profile_image_url';
  static const String animalUpdatedAtColumn = 'updated_at';

  static const String offlineUserId = 'offline_user_id';
  static const String offlineUserName = 'offline_user_name';
  static const String offlineAvatarUrl = 'offline_avatar_url';
  static const String offlineUserType = 'offline_user_type';
  static const String offlineAuthEmail = 'offline_auth_email';
  static const String offlineAuthSecret = 'offline_auth_secret';
  static const String offlineAuthAccounts = 'offline_auth_accounts';
  static const String offlineActiveEmail = 'offline_active_email';
  static const String preferredLanguage = 'preferred_language';
  static const String preferredThemeMode = 'preferred_theme_mode';
  static const String preferredLanguageScopePrefix = 'preferred_language_';
  static const String preferredThemeModeScopePrefix = 'preferred_theme_mode_';

  static const String managedClientsStoragePrefix = 'managed_clients_';
  static const String activeManagedClientStoragePrefix =
      'active_managed_client_';
  static const String managedClientAssignmentsStoragePrefix =
      'managed_client_animal_assignments_';
  static const String pendingRegistrations = 'pending_user_registrations';

  static const String managedClientsTable = 'managed_clients';
  static const String managedClientAnimalsTable = 'managed_client_animals';
  static const String managedClientVeterinarianIdColumn = 'veterinarian_id';
  static const String managedClientClientIdColumn = 'client_id';
}

class AnimalHiveFields {
  static const int id = 0;
  static const int userId = 1;
  static const int name = 2;
  static const int breed = 3;
  static const int age = 4;
  static const int symptoms = 5;
  static const int createdAt = 6;
  static const int updatedAt = 7;
  static const int weight = 8;
  static const int temperature = 9;
  static const int isSynced = 10;
  static const int imageUrl = 11;
  static const int profileImageUrl = 12;
  static const int pendingImagePath = 13;
  static const int ageLabel = 14;
  static const int isDeleted = 15;
  static const int totalFields = 16;
}
