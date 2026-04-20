class NotificationSchedulePolicy {
  final Duration reminderOffset;

  const NotificationSchedulePolicy({
    this.reminderOffset = const Duration(minutes: 20),
  });

  DateTime? resolveNotificationTime(DateTime scheduledTime, DateTime now) {
    final notifyAt = scheduledTime.subtract(reminderOffset);

    if (notifyAt.isBefore(now)) {
      return null;
    }

    return notifyAt;
  }
}
