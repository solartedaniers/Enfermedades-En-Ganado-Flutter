import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../utils/app_strings.dart';
import 'notification_channel_config.dart';
import 'notification_schedule_policy.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.handleNotificationResponse(response);
}

class NotificationService {
  static const String _launcherIconPath = '@mipmap/ic_launcher';
  static const String _channelId = 'agrovet_channel';
  static const String _snoozeActionId = 'snooze_reminder';
  static const String _completeActionId = 'complete_reminder';
  static const String _pendingCompletedKey = 'pending_completed_reminders';
  static const String _payloadReminderIdKey = 'reminder_id';
  static const String _payloadTitleKey = 'title';
  static const String _payloadBodyKey = 'body';
  static const String _payloadCancelIdsKey = 'cancel_notification_ids';
  static const int _notificationIdLimit = 2147483647;
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final StreamController<String> _completedReminderController =
      StreamController<String>.broadcast();
  static const NotificationSchedulePolicy _schedulePolicy =
      NotificationSchedulePolicy();

  static bool _initialized = false;

  static Stream<String> get completedReminderStream =>
      _completedReminderController.stream;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(_launcherIconPath);
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    await _requestPermissions();
    _initialized = true;
  }

  static Future<void> scheduleNotification({
    required int id,
    required String reminderId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required List<int> cancelNotificationIds,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    await _ensureInitializedForScheduling();

    final notifyAt = _schedulePolicy.resolveNotificationTime(
      scheduledTime,
      DateTime.now(),
    );

    if (notifyAt == null) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(notifyAt, tz.local),
      _buildChannelConfig().toNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchDateTimeComponents,
      payload: _buildPayload(
        reminderId: reminderId,
        title: title,
        body: body,
        cancelNotificationIds: cancelNotificationIds,
      ),
    );
  }

  static Future<List<int>> scheduleReminder({
    required String reminderId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required List<int> repeatWeekdays,
  }) async {
    if (repeatWeekdays.isEmpty) {
      final id = notificationIdFor(reminderId);
      await scheduleNotification(
        id: id,
        reminderId: reminderId,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        cancelNotificationIds: [id],
      );
      return [id];
    }

    final ids = repeatWeekdays
        .map((weekday) => notificationIdFor('$reminderId-$weekday'))
        .toList();
    var index = 0;
    for (final weekday in repeatWeekdays) {
      final id = ids[index];
      final nextOccurrence = _schedulePolicy.nextWeeklyOccurrence(
        scheduledTime,
        weekday,
        DateTime.now(),
      );
      await scheduleNotification(
        id: id,
        reminderId: reminderId,
        title: title,
        body: body,
        scheduledTime: nextOccurrence,
        cancelNotificationIds: ids,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      index++;
    }
    return ids;
  }

  static Future<void> cancelNotification(int id) async {
    await _ensureInitializedForScheduling();
    await _plugin.cancel(id);
  }

  static Future<void> cancelNotifications(Iterable<int> ids) async {
    for (final id in ids) {
      await cancelNotification(id);
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<Set<String>> takePendingCompletedReminderIds() async {
    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(_pendingCompletedKey) ?? [];
    await preferences.remove(_pendingCompletedKey);
    return ids.toSet();
  }

  static Future<void> handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final notificationId = response.id;
    if (notificationId != null) {
      await cancelNotification(notificationId);
    }

    final payload = _readPayload(response.payload);
    if (payload == null) return;

    switch (response.actionId) {
      case _snoozeActionId:
        await _snooze(payload);
        break;
      case _completeActionId:
        await _storeCompletedReminder(payload);
        break;
    }
  }

  static int notificationIdFor(String key) {
    var hash = 0;
    for (final unit in key.codeUnits) {
      hash = (hash * 31 + unit) & _notificationIdLimit;
    }
    return hash == 0 ? 1 : hash;
  }

  static NotificationChannelConfig _buildChannelConfig() {
    return NotificationChannelConfig(
      channelId: _channelId,
      channelName: AppStrings.t('notification_channel_name'),
      channelDescription: AppStrings.t('notification_channel_description'),
      actions: [
        AndroidNotificationAction(
          _snoozeActionId,
          AppStrings.t('notification_snooze_action'),
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          _completeActionId,
          AppStrings.t('notification_complete_action'),
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );
  }

  static Future<void> _requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  static String _buildPayload({
    required String reminderId,
    required String title,
    required String body,
    required List<int> cancelNotificationIds,
  }) {
    return jsonEncode({
      _payloadReminderIdKey: reminderId,
      _payloadTitleKey: title,
      _payloadBodyKey: body,
      _payloadCancelIdsKey: cancelNotificationIds,
    });
  }

  static _NotificationPayload? _readPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;

    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      return _NotificationPayload(
        reminderId: json[_payloadReminderIdKey] as String,
        title: json[_payloadTitleKey] as String,
        body: json[_payloadBodyKey] as String,
        cancelNotificationIds: _asIntList(json[_payloadCancelIdsKey]),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _snooze(_NotificationPayload payload) async {
    final snoozeAt = _schedulePolicy.resolveSnoozeTime(DateTime.now());
    final snoozeId = notificationIdFor(
      '${payload.reminderId}-${snoozeAt.millisecondsSinceEpoch}',
    );
    await scheduleNotification(
      id: snoozeId,
      reminderId: payload.reminderId,
      title: payload.title,
      body: payload.body,
      scheduledTime: snoozeAt,
      cancelNotificationIds: [snoozeId],
    );
  }

  static Future<void> _storeCompletedReminder(
    _NotificationPayload payload,
  ) async {
    await cancelNotifications(payload.cancelNotificationIds);

    final preferences = await SharedPreferences.getInstance();
    final current = preferences.getStringList(_pendingCompletedKey) ?? [];
    if (!current.contains(payload.reminderId)) {
      await preferences.setStringList(_pendingCompletedKey, [
        ...current,
        payload.reminderId,
      ]);
    }
    _completedReminderController.add(payload.reminderId);
  }

  static Future<void> _ensureInitializedForScheduling() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(_launcherIconPath);
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    _initialized = true;
  }

  static List<int> _asIntList(dynamic value) {
    if (value is! List) return [];

    return value
        .map((item) => item is int ? item : int.tryParse(item.toString()))
        .whereType<int>()
        .toList();
  }
}

class _NotificationPayload {
  final String reminderId;
  final String title;
  final String body;
  final List<int> cancelNotificationIds;

  const _NotificationPayload({
    required this.reminderId,
    required this.title,
    required this.body,
    required this.cancelNotificationIds,
  });
}
