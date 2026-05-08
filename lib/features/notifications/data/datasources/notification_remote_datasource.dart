import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_json_keys.dart';
import '../../../../core/constants/app_storage_keys.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  static const String _pendingHideColumnKey = 'column';
  static const String _pendingHideValueKey = 'value';
  final _supabaseClient = Supabase.instance.client;

  Future<List<NotificationModel>> getNotifications() async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) return _getPendingNotifications();

    final localNotifications = await _getPendingNotifications(currentUser.id);
    final hiddenNotificationIds = await _getPendingHiddenNotificationIds();

    try {
      final response = await _supabaseClient
          .from(AppStorageKeys.notificationsTable)
          .select(AppStorageKeys.notificationsWithAnimalsSelect)
          .eq(AppJsonKeys.userId, currentUser.id)
          .isFilter(AppJsonKeys.completedAt, null)
          .isFilter(AppJsonKeys.deletedAt, null)
          .order(AppJsonKeys.scheduledAt, ascending: true);

      final remoteNotifications = (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .where(
            (notification) => !hiddenNotificationIds.contains(notification.id),
          )
          .toList();
      final remoteIds =
          remoteNotifications.map((notification) => notification.id).toSet();

      return [
        ...remoteNotifications,
        ...localNotifications.where(
          (notification) => !remoteIds.contains(notification.id),
        ),
      ]..sort((first, second) {
          return first.scheduledAt.compareTo(second.scheduledAt);
        });
    } catch (_) {
      return localNotifications;
    }
  }

  Future<void> insertNotification(NotificationModel notification) async {
    try {
      await _supabaseClient
          .from(AppStorageKeys.notificationsTable)
          .insert(notification.toJson());
    } catch (_) {
      await _savePendingNotification(notification);
    }
  }

  Future<void> updateNotification(NotificationModel notification) async {
    try {
      await _supabaseClient
          .from(AppStorageKeys.notificationsTable)
          .upsert(notification.toJson());
    } catch (_) {
      await _savePendingNotification(notification);
    }
  }

  Future<void> deleteNotification(String id) async {
    await _hideNotification(id, AppJsonKeys.deletedAt);
  }

  Future<void> completeNotification(String id) async {
    await _hideNotification(id, AppJsonKeys.completedAt);
  }

  Future<void> syncPendingNotifications() async {
    final pendingNotifications = await _getPendingNotifications();

    for (final notification in pendingNotifications) {
      await _supabaseClient
          .from(AppStorageKeys.notificationsTable)
          .upsert(notification.toJson());
    }

    final pendingHides = await _getPendingHides();
    for (final hide in pendingHides) {
      await _supabaseClient
          .from(AppStorageKeys.notificationsTable)
          .update({hide.column: hide.value})
          .eq(AppJsonKeys.id, hide.id);
    }

    await _clearPendingNotifications();
    await _clearPendingHides();
  }

  Future<void> _hideNotification(String id, String column) async {
    final now = DateTime.now().toIso8601String();
    await _hidePendingNotification(id);

    try {
      await _supabaseClient
          .from(AppStorageKeys.notificationsTable)
          .update({column: now})
          .eq(AppJsonKeys.id, id);
    } catch (_) {
      await _savePendingHide(
        _PendingNotificationHide(
          id: id,
          column: column,
          value: now,
        ),
      );
    }
  }

  Future<List<NotificationModel>> _getPendingNotifications([
    String? userId,
  ]) async {
    final preferences = await SharedPreferences.getInstance();
    final values =
        preferences.getStringList(AppStorageKeys.pendingNotifications) ?? [];
    final notifications = values
        .map<NotificationModel?>((value) {
          try {
            if (!value.trimLeft().startsWith('{')) return null;

            final json = jsonDecode(value) as Map<String, dynamic>;
            return NotificationModel.fromJson(json);
          } catch (_) {
            return null;
          }
        })
        .whereType<NotificationModel>()
        .where((notification) => !notification.isHidden)
        .toList();

    if (userId == null) {
      return notifications;
    }

    return notifications
        .where((notification) => notification.userId == userId)
        .toList();
  }

  Future<void> _savePendingNotification(NotificationModel notification) async {
    final notifications = await _getPendingNotifications();
    final nextNotifications = [
      ...notifications.where((current) => current.id != notification.id),
      notification,
    ];
    await _savePendingNotifications(nextNotifications);
  }

  Future<void> _hidePendingNotification(String id) async {
    final notifications = await _getPendingNotifications();
    final nextNotifications =
        notifications.where((current) => current.id != id).toList();
    await _savePendingNotifications(nextNotifications);
  }

  Future<void> _clearPendingNotifications() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(AppStorageKeys.pendingNotifications);
  }

  Future<Set<String>> _getPendingHiddenNotificationIds() async {
    final pendingHides = await _getPendingHides();
    return pendingHides.map((hide) => hide.id).toSet();
  }

  Future<List<_PendingNotificationHide>> _getPendingHides() async {
    final preferences = await SharedPreferences.getInstance();
    final values =
        preferences.getStringList(AppStorageKeys.pendingNotificationHides) ??
            [];

    return values
        .map<_PendingNotificationHide?>((value) {
          try {
            return _PendingNotificationHide.fromJson(
              jsonDecode(value) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<_PendingNotificationHide>()
        .toList();
  }

  Future<void> _savePendingHide(_PendingNotificationHide hide) async {
    final pendingHides = await _getPendingHides();
    final nextHides = [
      ...pendingHides.where((current) => current.id != hide.id),
      hide,
    ];
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      AppStorageKeys.pendingNotificationHides,
      nextHides.map((current) => jsonEncode(current.toJson())).toList(),
    );
  }

  Future<void> _clearPendingHides() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(AppStorageKeys.pendingNotificationHides);
  }

  Future<void> _savePendingNotifications(
    List<NotificationModel> notifications,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      AppStorageKeys.pendingNotifications,
      notifications.map((notification) {
        return jsonEncode({
          ...notification.toJson(),
          AppJsonKeys.animals: {AppJsonKeys.name: notification.animalName},
        });
      }).toList(),
    );
  }
}

class _PendingNotificationHide {
  final String id;
  final String column;
  final String value;

  const _PendingNotificationHide({
    required this.id,
    required this.column,
    required this.value,
  });

  factory _PendingNotificationHide.fromJson(Map<String, dynamic> json) {
    return _PendingNotificationHide(
      id: json[AppJsonKeys.id] as String,
      column: json[NotificationRemoteDataSource._pendingHideColumnKey]
          as String,
      value:
          json[NotificationRemoteDataSource._pendingHideValueKey] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppJsonKeys.id: id,
      NotificationRemoteDataSource._pendingHideColumnKey: column,
      NotificationRemoteDataSource._pendingHideValueKey: value,
    };
  }
}
