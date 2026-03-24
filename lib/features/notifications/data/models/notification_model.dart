import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  NotificationModel({
    required super.id,
    required super.userId,
    required super.animalId,
    required super.animalName,
    required super.title,
    required super.message,
    required super.scheduledAt,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      animalId: json['animal_id'],
      animalName: json['animals']?['name'] ?? '',
      title: json['title'],
      message: json['message'],
      scheduledAt: DateTime.parse(json['scheduled_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'animal_id': animalId,
      'title': title,
      'message': message,
      'scheduled_at': scheduledAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}