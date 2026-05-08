import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_durations.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/app_date_formatter.dart';
import '../../../../../core/widgets/livestock_icon.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationListItem extends StatelessWidget {
  final NotificationEntity notification;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final theme = Theme.of(context);
    final isPast = notification.scheduledAt.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.medium),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.medium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: isPast
                  ? appColors.inputBorderLight
                  : appColors.selectionBackground,
              child: Icon(
                Icons.notifications_active,
                color: isPast
                    ? appColors.mutedForeground
                    : appColors.chipForeground,
              ),
            ),
            const SizedBox(width: AppSizes.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sectionTitle(theme),
                  ),
                  Text(
                    notification.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.xSmall),
                  Row(
                    children: [
                      LivestockIcon(
                        size: AppSizes.medium + 4,
                        padding: const EdgeInsets.only(right: 2),
                      ),
                      const SizedBox(width: AppSizes.xSmall),
                      Flexible(
                        child: Text(
                          notification.animalName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(
                            theme,
                            appColors.mutedForeground,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.medium),
                      Icon(
                        Icons.access_time,
                        size: AppSizes.medium,
                        color: appColors.mutedForeground,
                      ),
                      const SizedBox(width: AppSizes.xSmall),
                      Flexible(
                        flex: 2,
                        child: Text(
                          AppDateFormatter.shortDateTime(
                            notification.scheduledAt,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyStrong(
                            theme,
                            theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.xSmall),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: appColors.chipForeground,
                  ),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: appColors.chipForeground,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          duration: AppDurations.medium,
          delay: (index * 60).ms,
        );
  }
}
