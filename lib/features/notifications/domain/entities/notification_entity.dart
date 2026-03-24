class NotificationEntity {
  final String id;
  final String userId;
  final String animalId;
  final String animalName;
  final String title;
  final String message;
  final DateTime scheduledAt;
  final DateTime createdAt;

  NotificationEntity({
    required this.id,
    required this.userId,
    required this.animalId,
    required this.animalName,
    required this.title,
    required this.message,
    required this.scheduledAt,
    required this.createdAt,
  });
}