import '../../../../core/constants/app_account_status.dart';
import '../../../../core/constants/app_json_keys.dart';
import '../../../../core/constants/app_user_type.dart';

class AdminManagedUser {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String phone;
  final String location;
  final String? avatarUrl;
  final AppUserType userType;
  final AppAccountStatus accountStatus;
  final String? adminStatusMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminManagedUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.location,
    required this.avatarUrl,
    required this.userType,
    required this.accountStatus,
    required this.adminStatusMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminManagedUser.fromJson(Map<String, dynamic> json) {
    final firstName = (json[AppJsonKeys.firstName] as String?)?.trim() ?? '';
    final lastName = (json[AppJsonKeys.lastName] as String?)?.trim() ?? '';
    final fullName =
        (json[AppJsonKeys.fullName] as String?)?.trim() ??
        '$firstName $lastName'.trim();

    return AdminManagedUser(
      id: json[AppJsonKeys.id] as String? ?? '',
      username: (json[AppJsonKeys.username] as String?)?.trim() ?? '',
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
      email: (json[AppJsonKeys.email] as String?)?.trim() ?? '',
      phone: (json[AppJsonKeys.phone] as String?)?.trim() ?? '',
      location: (json[AppJsonKeys.location] as String?)?.trim() ?? '',
      avatarUrl: (json['avatar_url'] as String?)?.trim(),
      userType: AppUserTypeCodec.fromValue(
        json[AppJsonKeys.userType] as String?,
      ),
      accountStatus: AppAccountStatusCodec.fromValue(
        json[AppJsonKeys.accountStatus] as String?,
      ),
      adminStatusMessage:
          (json[AppJsonKeys.adminStatusMessage] as String?)?.trim(),
      createdAt:
          DateTime.tryParse(json[AppJsonKeys.createdAt] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json[AppJsonKeys.updatedAt] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String get displayName {
    if (fullName.isNotEmpty) {
      return fullName;
    }

    if (username.isNotEmpty) {
      return username;
    }

    return email;
  }
}

class AdminAnimalSnapshot {
  final String id;
  final String name;
  final String breed;
  final int age;
  final DateTime createdAt;

  const AdminAnimalSnapshot({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.createdAt,
  });

  factory AdminAnimalSnapshot.fromJson(Map<String, dynamic> json) {
    return AdminAnimalSnapshot(
      id: json[AppJsonKeys.id] as String? ?? '',
      name: (json[AppJsonKeys.name] as String?)?.trim() ?? '',
      breed: (json[AppJsonKeys.breed] as String?)?.trim() ?? '',
      age: json[AppJsonKeys.age] as int? ?? 0,
      createdAt:
          DateTime.tryParse(json[AppJsonKeys.createdAt] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class AdminMedicalRecordSnapshot {
  final String id;
  final String animalId;
  final String diagnosis;
  final DateTime createdAt;

  const AdminMedicalRecordSnapshot({
    required this.id,
    required this.animalId,
    required this.diagnosis,
    required this.createdAt,
  });

  factory AdminMedicalRecordSnapshot.fromJson(Map<String, dynamic> json) {
    return AdminMedicalRecordSnapshot(
      id: json[AppJsonKeys.id] as String? ?? '',
      animalId: json[AppJsonKeys.animalId] as String? ?? '',
      diagnosis:
          (json['diagnosis'] as String?)?.trim() ??
          (json['ai_result'] as String?)?.trim() ??
          '',
      createdAt:
          DateTime.tryParse(json[AppJsonKeys.createdAt] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class AdminNotificationSnapshot {
  final String id;
  final String title;
  final String message;
  final DateTime scheduledAt;

  const AdminNotificationSnapshot({
    required this.id,
    required this.title,
    required this.message,
    required this.scheduledAt,
  });

  factory AdminNotificationSnapshot.fromJson(Map<String, dynamic> json) {
    return AdminNotificationSnapshot(
      id: json[AppJsonKeys.id] as String? ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      message: (json['message'] as String?)?.trim() ?? '',
      scheduledAt:
          DateTime.tryParse(json['scheduled_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class AdminManagedUserDetails {
  final AdminManagedUser profile;
  final List<AdminAnimalSnapshot> animals;
  final List<AdminMedicalRecordSnapshot> medicalRecords;
  final List<AdminNotificationSnapshot> notifications;

  const AdminManagedUserDetails({
    required this.profile,
    required this.animals,
    required this.medicalRecords,
    required this.notifications,
  });

  int get animalCount => animals.length;
  int get medicalRecordCount => medicalRecords.length;
  int get notificationCount => notifications.length;
}
