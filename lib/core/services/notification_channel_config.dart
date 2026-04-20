import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationChannelConfig {
  final String channelId;
  final String channelName;
  final String channelDescription;

  const NotificationChannelConfig({
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
  });

  NotificationDetails toNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
  }
}
