import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/app_date_formatter.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../animals/domain/entities/animal_entity.dart';

class NotificationFormResult {
  final AnimalEntity animal;
  final String title;
  final String message;
  final DateTime scheduledAt;

  const NotificationFormResult({
    required this.animal,
    required this.title,
    required this.message,
    required this.scheduledAt,
  });
}

class NotificationFormSheet extends StatefulWidget {
  final List<AnimalEntity> animals;

  const NotificationFormSheet({
    super.key,
    required this.animals,
  });

  @override
  State<NotificationFormSheet> createState() => _NotificationFormSheetState();
}

class _NotificationFormSheetState extends State<NotificationFormSheet> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  AnimalEntity? _selectedAnimal;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    if (_selectedAnimal == null ||
        _titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('notifications_complete_fields'))),
      );
      return;
    }

    Navigator.of(context).pop(
      NotificationFormResult(
        animal: _selectedAnimal!,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        scheduledAt: _selectedDate!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                color: appColors.inputBorderLight,
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
          DropdownButtonFormField<AnimalEntity>(
            decoration: InputDecoration(
              labelText: AppStrings.t("notification_animal"),
              prefixIcon: const Icon(Icons.set_meal),
            ),
            items: widget.animals
                .map(
                  (animal) => DropdownMenuItem(
                    value: animal,
                    child: Text(animal.name),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedAnimal = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: AppStrings.t("notification_title"),
              prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: AppStrings.t("notification_message"),
              prefixIcon: const Icon(Icons.medical_services),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectDateTime,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: appColors.inputBorderLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: appColors.mutedForeground),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate != null
                        ? AppDateFormatter.shortDateTime(_selectedDate!)
                        : AppStrings.t("notification_date"),
                    style: TextStyle(
                      color: _selectedDate != null
                          ? null
                          : appColors.mutedForeground,
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
              onPressed: _submit,
              child: Text(AppStrings.t("notification_saved")),
            ),
          ),
        ],
      ),
    );
  }
}
