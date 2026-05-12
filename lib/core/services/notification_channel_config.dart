import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationChannelConfig {
  final String channelId;
  final String channelName;
  final String channelDescription;
  final List<AndroidNotificationAction> actions;

  const NotificationChannelConfig({
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    this.actions = const [],
  });

  NotificationDetails toNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        actions: actions,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        channelShowBadge: true,
        // Muestra la notificación completa en la pantalla de bloqueo.
        visibility: NotificationVisibility.public,
      ),
    );
  }
}
