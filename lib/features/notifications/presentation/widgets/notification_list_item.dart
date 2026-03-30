import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/app_date_formatter.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationListItem extends StatelessWidget {
  final NotificationEntity notification;
  final int index;
  final VoidCallback onDelete;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isPast = notification.scheduledAt.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPast
              ? appColors.inputBorderLight
              : appColors.selectionBackground,
          child: Icon(
            Icons.notifications_active,
            color: isPast ? appColors.mutedForeground : appColors.chipForeground,
          ),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.set_meal, size: 12, color: appColors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  notification.animalName,
                  style: TextStyle(
                    fontSize: 12,
                    color: appColors.mutedForeground,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: appColors.mutedForeground,
                ),
                const SizedBox(width: 4),
                Text(
                  AppDateFormatter.shortDateTime(notification.scheduledAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isPast ? appColors.danger : appColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: appColors.danger),
          onPressed: onDelete,
        ),
      ),
    ).animate().fadeIn(
          duration: 300.ms,
          delay: (index * 60).ms,
        );
  }
}
