import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_channel_config.dart';
import 'notification_schedule_policy.dart';
import '../utils/app_strings.dart';

class NotificationService {
  static const String _launcherIconPath = '@mipmap/ic_launcher';
  static const String _channelId = 'agrovet_channel';
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const NotificationSchedulePolicy _schedulePolicy =
      NotificationSchedulePolicy();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(_launcherIconPath);
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
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
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static NotificationChannelConfig _buildChannelConfig() {
    return NotificationChannelConfig(
      channelId: _channelId,
      channelName: AppStrings.t('notification_channel_name'),
      channelDescription: AppStrings.t('notification_channel_description'),
    );
  }
}
