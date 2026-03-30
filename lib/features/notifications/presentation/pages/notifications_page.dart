import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../animals/domain/entities/animal_entity.dart';
import '../../../animals/presentation/providers/animal_provider.dart';
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
  final _notificationDataSource = NotificationRemoteDataSource();
  List<NotificationEntity> _notifications = [];
  List<AnimalEntity> _animals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final notifications = await _notificationDataSource.getNotifications();
      final animals = await ref.read(animalRepositoryProvider).getAnimals();

      if (mounted) {
        setState(() {
          _notifications = notifications;
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
    final isOnline = await ConnectivityService.checkAndNotify(
      context,
      message: AppStrings.t('notifications_need_internet'),
    );

    if (!isOnline || !mounted) return;

    if (_animals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('notifications_register_animal_first')),
        ),
      );
      return;
    }

    final formResult = await showModalBottomSheet<NotificationFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationFormSheet(animals: _animals),
    );

    if (formResult == null) return;

    await _saveNotification(
      animal: formResult.animal,
      title: formResult.title,
      message: formResult.message,
      scheduledAt: formResult.scheduledAt,
    );
  }

  Future<void> _saveNotification({
    required AnimalEntity animal,
    required String title,
    required String message,
    required DateTime scheduledAt,
  }) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final id = const Uuid().v4();
      final notificationId = Random().nextInt(100000);

      final model = NotificationModel(
        id: id,
        userId: userId,
        animalId: animal.id,
        animalName: animal.name,
        title: title,
        message: message,
        scheduledAt: scheduledAt,
        createdAt: DateTime.now(),
      );

      await _notificationDataSource.insertNotification(model);

      await NotificationService.scheduleNotification(
        id: notificationId,
        title: title,
        body:
            "${AppStrings.t("notification_reminder")}: $message (${animal.name})",
        scheduledTime: scheduledAt,
      );

      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t("notification_saved"))),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.t("unexpected_error")}: $error'),
          ),
        );
      }
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
              style: TextStyle(color: context.appColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _notificationDataSource.deleteNotification(notification.id);
    await _load();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t("notification_deleted"))),
      );
    }
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
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 80,
                        color: appColors.inputBorderLight,
                      ).animate().fadeIn(duration: 400.ms).scale(),
                      const SizedBox(height: 16),
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
                        onDelete: () => _deleteNotification(notification),
                      );
                    },
                  ),
                ),
    );
  }
}
