class NotificationEntity {
  final String id;
  final String userId;
  final String animalId;
  final String animalName;
  final String title;
  final String message;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final List<int> localNotificationIds;
  final List<int> repeatWeekdays;
  final DateTime? completedAt;
  final DateTime? deletedAt;

  NotificationEntity({
    required this.id,
    required this.userId,
    required this.animalId,
    required this.animalName,
    required this.title,
    required this.message,
    required this.scheduledAt,
    required this.createdAt,
    required this.localNotificationIds,
    required this.repeatWeekdays,
    this.completedAt,
    this.deletedAt,
  });

  bool get repeatsWeekly => repeatWeekdays.isNotEmpty;
  bool get isHidden => completedAt != null || deletedAt != null;
}
