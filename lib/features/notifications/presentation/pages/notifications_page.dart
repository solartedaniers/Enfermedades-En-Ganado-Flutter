import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../animals/domain/entities/animal_entity.dart';
import '../../../animals/presentation/providers/animal_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/models/notification_model.dart';
import '../../domain/entities/notification_entity.dart';
import '../widgets/notification_form_sheet.dart';
import '../widgets/notification_list_item.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  static const String _messagePlaceholder = 'message';
  static const String _animalPlaceholder = 'animal';
  final _notificationDataSource = NotificationRemoteDataSource();
  List<NotificationEntity> _notifications = [];
  List<AnimalEntity> _animals = [];
  bool _isLoading = true;
  StreamSubscription<String>? _completedReminderSubscription;

  @override
  void initState() {
    super.initState();
    _completedReminderSubscription =
        NotificationService.completedReminderStream.listen(
          _deleteCompletedNotification,
        );
    _load();
  }

  @override
  void dispose() {
    _completedReminderSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      var notifications = await _notificationDataSource.getNotifications();
      if (await _completePendingNotifications(notifications)) {
        notifications = await _notificationDataSource.getNotifications();
      }
      final animals = await _loadAvailableAnimals();
      final allowedAnimalIds = animals.map((animal) => animal.id).toSet();
      final profile = ref.read(profileProvider);

      final visibleNotifications = profile.isVeterinarian
          ? notifications
              .where(
                (notification) => allowedAnimalIds.contains(
                  notification.animalId,
                ),
              )
              .toList()
          : notifications;

      if (mounted) {
        setState(() {
          _notifications = visibleNotifications;
          _animals = animals;
        });
      }
    } catch (error) {
      debugPrint("Error loading notifications: $error");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addNotification() async {
    if (_animals.isEmpty) {
      final animals = await _loadAvailableAnimals(refresh: true);
      if (!mounted) return;

      setState(() => _animals = animals);
    }

    if (_animals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('notifications_register_animal_first')),
        ),
      );
      return;
    }

    if (!mounted) return;

    final formResult = await _showNotificationForm();

    if (formResult == null) return;

    await _saveNotification(
      animal: formResult.animal,
      title: formResult.title,
      message: formResult.message,
      scheduledAt: formResult.scheduledAt,
      repeatWeekdays: formResult.repeatWeekdays,
    );
  }

  Future<void> _editNotification(NotificationEntity notification) async {
    AnimalEntity? selectedAnimal;
    for (final animal in _animals) {
      if (animal.id == notification.animalId) {
        selectedAnimal = animal;
        break;
      }
    }

    if (selectedAnimal == null) return;

    final formResult = await _showNotificationForm(
      initialValue: NotificationFormResult(
        animal: selectedAnimal,
        title: notification.title,
        message: notification.message,
        scheduledAt: notification.scheduledAt,
        repeatWeekdays: notification.repeatWeekdays,
      ),
    );

    if (formResult == null) return;

    await _updateNotification(
      notification: notification,
      animal: formResult.animal,
      title: formResult.title,
      message: formResult.message,
      scheduledAt: formResult.scheduledAt,
      repeatWeekdays: formResult.repeatWeekdays,
    );
  }

  Future<NotificationFormResult?> _showNotificationForm({
    NotificationFormResult? initialValue,
  }) async {
    if (!mounted) return null;

    final backgroundColor = Theme.of(context)
        .colorScheme
        .surface
        .withValues(alpha: 0);

    return showModalBottomSheet<NotificationFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      builder: (_) => NotificationFormSheet(
        animals: _animals,
        initialValue: initialValue,
      ),
    );
  }

  Future<void> _saveNotification({
    required AnimalEntity animal,
    required String title,
    required String message,
    required DateTime scheduledAt,
    required List<int> repeatWeekdays,
  }) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final id = const Uuid().v4();
      final notificationBody = AppStrings.format(
        "notification_body",
        {
          _messagePlaceholder: message,
          _animalPlaceholder: animal.name,
        },
      );
      final localNotificationIds = await NotificationService.scheduleReminder(
        reminderId: id,
        title: title,
        body: notificationBody,
        scheduledTime: scheduledAt,
        repeatWeekdays: repeatWeekdays,
      );

      final model = NotificationModel(
        id: id,
        userId: userId,
        animalId: animal.id,
        animalName: animal.name,
        title: title,
        message: message,
        scheduledAt: scheduledAt,
        createdAt: DateTime.now(),
        localNotificationIds: localNotificationIds,
        repeatWeekdays: repeatWeekdays,
      );

      await _notificationDataSource.insertNotification(model);

      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t("notification_saved"))),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.t("unexpected_error")}: $error'),
        ),
      );
    }
  }

  Future<void> _updateNotification({
    required NotificationEntity notification,
    required AnimalEntity animal,
    required String title,
    required String message,
    required DateTime scheduledAt,
    required List<int> repeatWeekdays,
  }) async {
    try {
      await NotificationService.cancelNotifications(
        _resolveLocalNotificationIds(notification),
      );

      final notificationBody = AppStrings.format(
        "notification_body",
        {
          _messagePlaceholder: message,
          _animalPlaceholder: animal.name,
        },
      );
      final localNotificationIds = await NotificationService.scheduleReminder(
        reminderId: notification.id,
        title: title,
        body: notificationBody,
        scheduledTime: scheduledAt,
        repeatWeekdays: repeatWeekdays,
      );

      final model = NotificationModel(
        id: notification.id,
        userId: notification.userId,
        animalId: animal.id,
        animalName: animal.name,
        title: title,
        message: message,
        scheduledAt: scheduledAt,
        createdAt: notification.createdAt,
        localNotificationIds: localNotificationIds,
        repeatWeekdays: repeatWeekdays,
      );

      await _notificationDataSource.updateNotification(model);
      await _load();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.t("unexpected_error")}: $error'),
        ),
      );
    }
  }

  Future<void> _deleteNotification(NotificationEntity notification) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.t("delete_notification")),
        content: Text(AppStrings.t("delete_notification_confirm")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.t("cancel")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppStrings.t("delete_notification"),
              style: TextStyle(color: context.appColors.chipForeground),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await NotificationService.cancelNotifications(
      _resolveLocalNotificationIds(notification),
    );
    await _notificationDataSource.deleteNotification(notification.id);
    await _load();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.t("notification_deleted"))),
    );
  }

  Future<bool> _completePendingNotifications(
    List<NotificationEntity> notifications,
  ) async {
    final pendingIds =
        await NotificationService.takePendingCompletedReminderIds();
    if (pendingIds.isEmpty) return false;

    final notificationMap = {
      for (final notification in notifications) notification.id: notification,
    };

    for (final id in pendingIds) {
      final notification = notificationMap[id];
      if (notification != null) {
        await NotificationService.cancelNotifications(
          _resolveLocalNotificationIds(notification),
        );
      }
      await _notificationDataSource.completeNotification(id);
    }
    return true;
  }

  Future<void> _deleteCompletedNotification(String id) async {
    NotificationEntity? notification;
    for (final current in _notifications) {
      if (current.id == id) {
        notification = current;
        break;
      }
    }

    if (notification != null) {
      await NotificationService.cancelNotifications(
        _resolveLocalNotificationIds(notification),
      );
    }
    await _notificationDataSource.completeNotification(id);
    await _load();
  }

  Future<List<AnimalEntity>> _loadAvailableAnimals({
    bool refresh = false,
  }) async {
    if (refresh) {
      ref.invalidate(animalsListProvider);
      ref.invalidate(rawAnimalsListProvider);
    }

    final animals = await ref.read(animalsListProvider.future);
    if (animals.isNotEmpty || ref.read(profileProvider).isVeterinarian) {
      return animals;
    }

    final userId = ref.read(currentUserIdProvider);
    final rawAnimals = await ref.read(rawAnimalsListProvider.future);
    if (userId == null) {
      return rawAnimals;
    }

    return rawAnimals.where((animal) => animal.userId == userId).toList();
  }

  List<int> _resolveLocalNotificationIds(NotificationEntity notification) {
    if (notification.localNotificationIds.isNotEmpty) {
      return notification.localNotificationIds;
    }

    if (notification.repeatWeekdays.isEmpty) {
      return [NotificationService.notificationIdFor(notification.id)];
    }

    return notification.repeatWeekdays
        .map((weekday) => NotificationService.notificationIdFor(
              '${notification.id}-$weekday',
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t("notifications"))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNotification,
        icon: const Icon(Icons.add_alert),
        label: Text(AppStrings.t("add_notification")),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: AppSizes.notificationEmptyIcon,
                        color: appColors.inputBorderLight,
                      ).animate().fadeIn(duration: AppDurations.medium).scale(),
                      const SizedBox(height: AppSizes.large),
                      Text(
                        AppStrings.t("no_notifications"),
                        style: TextStyle(color: appColors.subduedForeground),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];

                      return NotificationListItem(
                        notification: notification,
                        index: index,
                        onEdit: () => _editNotification(notification),
                        onDelete: () => _deleteNotification(notification),
                      );
                    },
                  ),
                ),
    );
  }
}
