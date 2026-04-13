import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_json_keys.dart';
import '../constants/app_storage_keys.dart';
import '../constants/app_user_type.dart';

class PendingUserRegistration {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String username;
  final String phone;
  final String location;
  final AppUserType userType;
  final DateTime createdAt;

  const PendingUserRegistration({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.phone,
    required this.location,
    required this.userType,
    required this.createdAt,
  });

  factory PendingUserRegistration.fromJson(Map<String, dynamic> json) {
    return PendingUserRegistration(
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      firstName: json[AppJsonKeys.firstName] as String? ?? '',
      lastName: json[AppJsonKeys.lastName] as String? ?? '',
      username: json[AppJsonKeys.username] as String? ?? '',
      phone: json[AppJsonKeys.phone] as String? ?? '',
      location: json[AppJsonKeys.location] as String? ?? '',
      userType: AppUserTypeCodec.fromValue(
        json[AppJsonKeys.userType] as String?,
      ),
      createdAt: DateTime.tryParse(json[AppJsonKeys.createdAt] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      AppJsonKeys.firstName: firstName,
      AppJsonKeys.lastName: lastName,
      AppJsonKeys.username: username,
      AppJsonKeys.phone: phone,
      AppJsonKeys.location: location,
      AppJsonKeys.userType: userType.storageValue,
      AppJsonKeys.createdAt: createdAt.toIso8601String(),
    };
  }
}

class PendingUserRegistrationService {
  Future<List<PendingUserRegistration>> getPendingRegistrations() async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getString(AppStorageKeys.pendingRegistrations);

    if (rawValue == null || rawValue.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawValue) as List<dynamic>;
    return decoded
        .map(
          (item) =>
              PendingUserRegistration.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> queueRegistration(PendingUserRegistration registration) async {
    final prefs = await SharedPreferences.getInstance();
    final registrations = await getPendingRegistrations();
    final normalizedEmail = registration.email.trim().toLowerCase();
    final filteredRegistrations = registrations
        .where((item) => item.email.trim().toLowerCase() != normalizedEmail)
        .toList()
      ..add(
        PendingUserRegistration(
          email: normalizedEmail,
          password: registration.password,
          firstName: registration.firstName.trim(),
          lastName: registration.lastName.trim(),
          username: registration.username.trim(),
          phone: registration.phone.trim(),
          location: registration.location.trim(),
          userType: registration.userType,
          createdAt: registration.createdAt,
        ),
      );

    await prefs.setString(
      AppStorageKeys.pendingRegistrations,
      jsonEncode(filteredRegistrations.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> removeRegistration(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = email.trim().toLowerCase();
    final registrations = await getPendingRegistrations();
    final filteredRegistrations = registrations
        .where((item) => item.email.trim().toLowerCase() != normalizedEmail)
        .toList();

    await prefs.setString(
      AppStorageKeys.pendingRegistrations,
      jsonEncode(filteredRegistrations.map((item) => item.toJson()).toList()),
    );
  }
}
