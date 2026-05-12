import '../../domain/entities/notification_entity.dart';
import '../../../../core/constants/app_json_keys.dart';

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
    required super.localNotificationIds,
    required super.repeatWeekdays,
    super.completedAt,
    super.deletedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final animalJson = json[AppJsonKeys.animals] as Map<String, dynamic>?;

    return NotificationModel(
      id: json[AppJsonKeys.id] as String,
      userId: json[AppJsonKeys.userId] as String,
      animalId: json[AppJsonKeys.animalId] as String,
      animalName: animalJson?[AppJsonKeys.name] as String? ?? '',
      title: json[AppJsonKeys.title] as String,
      message: json[AppJsonKeys.message] as String,
      scheduledAt: DateTime.parse(json[AppJsonKeys.scheduledAt] as String),
      createdAt: DateTime.parse(json[AppJsonKeys.createdAt] as String),
      localNotificationIds: _asIntList(
        json[AppJsonKeys.localNotificationIds],
      ),
      repeatWeekdays: _asIntList(json[AppJsonKeys.repeatWeekdays]),
      completedAt: json[AppJsonKeys.completedAt] == null
          ? null
          : DateTime.parse(json[AppJsonKeys.completedAt] as String),
      deletedAt: json[AppJsonKeys.deletedAt] == null
          ? null
          : DateTime.parse(json[AppJsonKeys.deletedAt] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppJsonKeys.id: id,
      AppJsonKeys.userId: userId,
      AppJsonKeys.animalId: animalId,
      AppJsonKeys.title: title,
      AppJsonKeys.message: message,
      AppJsonKeys.scheduledAt: scheduledAt.toIso8601String(),
      AppJsonKeys.createdAt: createdAt.toIso8601String(),
      AppJsonKeys.localNotificationIds: localNotificationIds,
      AppJsonKeys.repeatWeekdays: repeatWeekdays,
      AppJsonKeys.completedAt: completedAt?.toIso8601String(),
      AppJsonKeys.deletedAt: deletedAt?.toIso8601String(),
    };
  }

  static List<int> _asIntList(dynamic value) {
    if (value is! List) return [];

    return value
        .map((item) => item is int ? item : int.tryParse(item.toString()))
        .whereType<int>()
        .toList();
  }
}
