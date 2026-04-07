import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_durations.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
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
      margin: const EdgeInsets.only(bottom: AppSizes.medium),
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
          style: AppTextStyles.sectionTitle(Theme.of(context)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: AppSizes.xSmall),
            Row(
              children: [
                Icon(
                  Icons.set_meal,
                  size: AppSizes.medium,
                  color: appColors.mutedForeground,
                ),
                const SizedBox(width: AppSizes.xSmall),
                Text(
                  notification.animalName,
                  style: AppTextStyles.caption(
                    Theme.of(context),
                    appColors.mutedForeground,
                  ),
                ),
                const SizedBox(width: AppSizes.medium),
                Icon(
                  Icons.access_time,
                  size: AppSizes.medium,
                  color: appColors.mutedForeground,
                ),
                const SizedBox(width: AppSizes.xSmall),
                Text(
                  AppDateFormatter.shortDateTime(notification.scheduledAt),
                  style: AppTextStyles.caption(
                    Theme.of(context),
                    isPast ? appColors.danger : appColors.mutedForeground,
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
          duration: AppDurations.medium,
          delay: (index * 60).ms,
        );
  }
}
