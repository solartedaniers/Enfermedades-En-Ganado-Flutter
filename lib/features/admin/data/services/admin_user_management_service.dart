import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_account_status.dart';
import '../../../../core/constants/app_json_keys.dart';
import '../../../../core/constants/app_user_type.dart';
import '../models/admin_managed_user.dart';

class AdminUserManagementService {
  final SupabaseClient _client;

  AdminUserManagementService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<List<AdminManagedUser>> fetchUsers() async {
    final response = await _client
        .from('profiles')
        .select()
        .order(AppJsonKeys.updatedAt, ascending: false);

    return (response as List<dynamic>)
        .map((item) => AdminManagedUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminManagedUserDetails> fetchUserDetails(String userId) async {
    final responses = await Future.wait([
      _client.from('profiles').select().eq(AppJsonKeys.id, userId).single(),
      _client
          .from('animals')
          .select()
          .eq(AppJsonKeys.userId, userId)
          .order(AppJsonKeys.createdAt, ascending: false),
      _client
          .from('medical_records')
          .select()
          .eq(AppJsonKeys.userId, userId)
          .order(AppJsonKeys.createdAt, ascending: false),
      _client
          .from('notifications')
          .select()
          .eq(AppJsonKeys.userId, userId)
          .order('scheduled_at', ascending: false),
    ]);

    final profile = AdminManagedUser.fromJson(
      responses[0] as Map<String, dynamic>,
    );
    final animals = (responses[1] as List<dynamic>)
        .map((item) => AdminAnimalSnapshot.fromJson(item as Map<String, dynamic>))
        .toList();
    final medicalRecords = (responses[2] as List<dynamic>)
        .map(
          (item) =>
              AdminMedicalRecordSnapshot.fromJson(item as Map<String, dynamic>),
        )
        .toList();
    final notifications = (responses[3] as List<dynamic>)
        .map(
          (item) =>
              AdminNotificationSnapshot.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    return AdminManagedUserDetails(
      profile: profile,
      animals: animals,
      medicalRecords: medicalRecords,
      notifications: notifications,
    );
  }

  Future<void> updateUserProfile({
    required String userId,
    required String username,
    required String firstName,
    required String lastName,
    required String phone,
    required String location,
    required AppUserType userType,
  }) async {
    final normalizedFirstName = firstName.trim();
    final normalizedLastName = lastName.trim();

    await _client.from('profiles').update({
      AppJsonKeys.username: username.trim(),
      AppJsonKeys.firstName: normalizedFirstName,
      AppJsonKeys.lastName: normalizedLastName,
      AppJsonKeys.fullName: '$normalizedFirstName $normalizedLastName'.trim(),
      AppJsonKeys.name: normalizedFirstName,
      AppJsonKeys.phone: phone.trim(),
      AppJsonKeys.location: location.trim(),
      AppJsonKeys.userType: userType.storageValue,
    }).eq(AppJsonKeys.id, userId);
  }

  Future<void> updateUserStatus({
    required String userId,
    required AppAccountStatus status,
    String? adminMessage,
  }) async {
    final currentAdminId = _client.auth.currentUser?.id;
    if (currentAdminId == null) {
      throw StateError('Admin session unavailable');
    }

    if (currentAdminId == userId && status != AppAccountStatus.active) {
      throw StateError('You cannot deactivate your own account.');
    }

    final normalizedMessage = adminMessage?.trim();

    await _client.from('profiles').update({
      AppJsonKeys.accountStatus: status.storageValue,
      AppJsonKeys.adminStatusMessage: status.isActive
          ? null
          : (normalizedMessage?.isNotEmpty == true ? normalizedMessage : null),
      AppJsonKeys.adminStatusChangedAt: DateTime.now().toIso8601String(),
      AppJsonKeys.adminStatusChangedBy: currentAdminId,
    }).eq(AppJsonKeys.id, userId);
  }
}
