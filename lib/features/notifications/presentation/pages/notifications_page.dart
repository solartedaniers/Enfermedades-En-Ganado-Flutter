import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// --- Servicios y Core ---
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/utils/app_strings.dart';

// --- Animales ---
import '../../../animals/data/datasources/animal_remote_datasource.dart';
import '../../../animals/data/models/animal_model.dart';

// --- Notificaciones ---
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/models/notification_model.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _ds = NotificationRemoteDataSource();
  List<NotificationEntity> _notifications = [];
  List<AnimalModel> _animals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    
    try {
      final notifs = await _ds.getNotifications();
      final animals = await AnimalRemoteDataSource().getAnimals();
      
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _animals = animals;
        });
      }
    } catch (e) {
      debugPrint("Error loading notifications: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addNotification() async {
    // --- Validación de Internet ---
    final isOnline = await ConnectivityService.checkAndNotify(
      context,
      message: "Necesitas internet para programar notificaciones",
    );
    
    if (!isOnline || !mounted) return;

    if (_animals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Primero registra un animal")),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    AnimalModel? selectedAnimal;
    DateTime? selectedDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.t("add_notification"),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<AnimalModel>(
                decoration: InputDecoration(
                  labelText: AppStrings.t("notification_animal"),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.set_meal),
                ),
                items: _animals
                    .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(a.name),
                        ))
                    .toList(),
                onChanged: (v) => setModal(() => selectedAnimal = v),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.t("notification_title"),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: messageCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.t("notification_message"),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.medical_services),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(hours: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date == null || !ctx.mounted) return;

                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time == null) return;

                  setModal(() {
                    selectedDate = DateTime(date.year, date.month, date.day,
                        time.hour, time.minute);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        selectedDate != null
                            ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} ${selectedDate!.hour}:${selectedDate!.minute.toString().padLeft(2, '0')}"
                            : AppStrings.t("notification_date"),
                        style: TextStyle(
                          color: selectedDate != null ? null : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedAnimal == null ||
                        titleCtrl.text.isEmpty ||
                        messageCtrl.text.isEmpty ||
                        selectedDate == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text("Completa todos los campos")),
                      );
                      return;
                    }

                    final nav = Navigator.of(ctx);

                    await _saveNotification(
                      animal: selectedAnimal!,
                      title: titleCtrl.text.trim(),
                      message: messageCtrl.text.trim(),
                      scheduledAt: selectedDate!,
                    );

                    if (nav.canPop()) nav.pop();
                  },
                  child: Text(AppStrings.t("notification_saved")),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveNotification({
    required AnimalModel animal,
    required String title,
    required String message,
    required DateTime scheduledAt,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final id = const Uuid().v4();
      final notifId = Random().nextInt(100000);

      final model = NotificationModel(
        id: id,
        userId: user.id,
        animalId: animal.id,
        animalName: animal.name,
        title: title,
        message: message,
        scheduledAt: scheduledAt,
        createdAt: DateTime.now(),
      );

      await _ds.insertNotification(model);

      await NotificationService.scheduleNotification(
        id: notifId,
        title: title,
        body: "${AppStrings.t("notification_reminder")}: $message (${animal.name})",
        scheduledTime: scheduledAt,
      );

      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t("notification_saved"))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _deleteNotification(NotificationEntity n) async {
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
            child: Text(AppStrings.t("delete_notification"),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;

    await _ds.deleteNotification(n.id);
    await _load();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t("notification_deleted"))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t("notifications"))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNotification,
        icon: const Icon(Icons.add_alert),
        label: Text(AppStrings.t("add_notification")),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                              size: 80, color: Colors.grey[400])
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .scale(),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.t("no_notifications"),
                        style: TextStyle(color: Colors.grey[600]),
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
                      final n = _notifications[index];
                      final isPast = n.scheduledAt.isBefore(DateTime.now());

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPast
                                ? Colors.grey.shade200
                                : const Color(0xFFE8F5E9),
                            child: Icon(
                              Icons.notifications_active,
                              color: isPast ? Colors.grey : const Color(0xFF2E7D32),
                            ),
                          ),
                          title: Text(n.title,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.message),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.set_meal,
                                      size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(n.animalName,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.access_time,
                                      size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${n.scheduledAt.day}/${n.scheduledAt.month}/${n.scheduledAt.year} ${n.scheduledAt.hour}:${n.scheduledAt.minute.toString().padLeft(2, '0')}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isPast ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteNotification(n),
                          ),
                        ),
                      ).animate().fadeIn(
                            duration: 300.ms,
                            delay: (index * 60).ms,
                          );
                    },
                  ),
                ),
    );
  }
}