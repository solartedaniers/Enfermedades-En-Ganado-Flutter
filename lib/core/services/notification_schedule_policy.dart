class NotificationSchedulePolicy {
  final Duration snoozeDuration;

  const NotificationSchedulePolicy({
    this.snoozeDuration = const Duration(minutes: 5),
  });

  DateTime? resolveNotificationTime(DateTime scheduledTime, DateTime now) {
    if (scheduledTime.isBefore(now)) {
      return null;
    }

    return scheduledTime;
  }

  DateTime resolveSnoozeTime(DateTime now) {
    return now.add(snoozeDuration);
  }

  DateTime nextWeeklyOccurrence(DateTime startAt, int weekday, DateTime now) {
    var candidate = DateTime(
      startAt.year,
      startAt.month,
      startAt.day,
      startAt.hour,
      startAt.minute,
    );
    final dayDifference = (weekday - candidate.weekday) % DateTime.daysPerWeek;
    candidate = candidate.add(Duration(days: dayDifference));

    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: DateTime.daysPerWeek));
    }

    return candidate;
  }
}
