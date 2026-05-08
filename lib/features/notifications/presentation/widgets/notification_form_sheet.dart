import 'package:flutter/material.dart';

import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/app_date_formatter.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/widgets/livestock_icon.dart';
import '../../../animals/domain/entities/animal_entity.dart';

class NotificationFormResult {
  final AnimalEntity animal;
  final String title;
  final String message;
  final DateTime scheduledAt;
  final List<int> repeatWeekdays;

  const NotificationFormResult({
    required this.animal,
    required this.title,
    required this.message,
    required this.scheduledAt,
    required this.repeatWeekdays,
  });
}

class NotificationFormSheet extends StatefulWidget {
  final List<AnimalEntity> animals;
  final NotificationFormResult? initialValue;

  const NotificationFormSheet({
    super.key,
    required this.animals,
    this.initialValue,
  });

  @override
  State<NotificationFormSheet> createState() => _NotificationFormSheetState();
}

class _NotificationFormSheetState extends State<NotificationFormSheet> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  AnimalEntity? _selectedAnimal;
  DateTime? _selectedDate;
  bool _repeatWeekly = false;
  final Set<int> _selectedWeekdays = {};

  @override
  void initState() {
    super.initState();
    final initialValue = widget.initialValue;
    if (initialValue == null) return;

    _selectedAnimal = initialValue.animal;
    _titleController.text = initialValue.title;
    _messageController.text = initialValue.message;
    _selectedDate = initialValue.scheduledAt;
    _repeatWeekly = initialValue.repeatWeekdays.isNotEmpty;
    _selectedWeekdays.addAll(initialValue.repeatWeekdays);
  }

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
      if (_repeatWeekly) {
        _selectedWeekdays.add(_selectedDate!.weekday);
      }
    });
  }

  void _submit() {
    if (_selectedAnimal == null ||
        _titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty ||
        _selectedDate == null ||
        (_repeatWeekly && _selectedWeekdays.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('notifications_complete_fields'))),
      );
      return;
    }

    if (!_repeatWeekly && !_selectedDate!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('notification_future_required'))),
      );
      return;
    }

    Navigator.of(context).pop(
      NotificationFormResult(
        animal: _selectedAnimal!,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        scheduledAt: _selectedDate!,
        repeatWeekdays: _repeatWeekly ? _selectedWeekdays.toList() : [],
      ),
    );
  }

  void _toggleRepeat(bool value) {
    setState(() {
      _repeatWeekly = value;
      if (!value) {
        _selectedWeekdays.clear();
        return;
      }
      if (_selectedDate != null) {
        _selectedWeekdays.add(_selectedDate!.weekday);
      }
    });
  }

  void _toggleWeekday(int weekday) {
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        _selectedWeekdays.remove(weekday);
      } else {
        _selectedWeekdays.add(weekday);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            left: AppSizes.pagePadding,
            right: AppSizes.pagePadding,
            top: AppSizes.pagePadding,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                AppSizes.pagePadding,
          ),
          child: ListView(
            controller: scrollController,
            shrinkWrap: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _buildContent(context, appColors),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, AppThemeColors appColors) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: AppSizes.modalHandleWidth,
              height: AppSizes.modalHandleHeight,
              decoration: BoxDecoration(
                color: appColors.inputBorderLight,
                borderRadius: BorderRadius.circular(AppSizes.modalHandleRadius),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.large),
          Text(
            AppStrings.t("add_notification"),
            style: AppTextStyles.sectionTitle(Theme.of(context)),
          ),
          const SizedBox(height: AppSizes.large),
          DropdownButtonFormField<AnimalEntity>(
            decoration: InputDecoration(
              labelText: AppStrings.t("notification_animal"),
              prefixIcon: const LivestockIcon(
                padding: EdgeInsets.all(12),
              ),
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
          const SizedBox(height: AppSizes.medium),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: AppStrings.t("notification_title"),
              prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: AppSizes.medium),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: AppStrings.t("notification_message"),
              prefixIcon: const Icon(Icons.medical_services),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSizes.medium),
          InkWell(
            onTap: _selectDateTime,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.sectionSpacing),
              decoration: BoxDecoration(
                border: Border.all(color: appColors.inputBorderLight),
                borderRadius: BorderRadius.circular(AppSizes.small),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: appColors.mutedForeground),
                  const SizedBox(width: AppSizes.medium),
                  Text(
                    _selectedDate != null
                        ? AppDateFormatter.shortDateTime(_selectedDate!)
                        : AppStrings.t("notification_date"),
                    style: _selectedDate != null
                        ? AppTextStyles.bodyStrong(
                            Theme.of(context),
                            Theme.of(context).colorScheme.onSurface,
                          )
                        : AppTextStyles.bodyMuted(
                            Theme.of(context),
                            appColors.mutedForeground,
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.medium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.t('notification_repeat_weekly')),
            subtitle: Text(
              AppStrings.t(
                _repeatWeekly
                    ? 'notification_repeat_weekly_hint'
                    : 'notification_once_hint',
              ),
            ),
            value: _repeatWeekly,
            onChanged: _toggleRepeat,
          ),
          if (_repeatWeekly) ...[
            const SizedBox(height: AppSizes.small),
            Wrap(
              spacing: AppSizes.xSmall,
              runSpacing: AppSizes.xSmall,
              children: _weekdayOptions
                  .map(
                    (weekday) => FilterChip(
                      label: Text(AppStrings.t(weekday.labelKey)),
                      selected: _selectedWeekdays.contains(weekday.value),
                      onSelected: (_) => _toggleWeekday(weekday.value),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: AppSizes.xLarge),
          SizedBox(
            width: double.infinity,
            height: AppSizes.largeButtonHeight,
            child: ElevatedButton(
              onPressed: _submit,
              child: Text(AppStrings.t("notification_saved")),
            ),
          ),
          ],
    );
  }

  static const List<_WeekdayOption> _weekdayOptions = [
    _WeekdayOption(DateTime.monday, 'weekday_mon'),
    _WeekdayOption(DateTime.tuesday, 'weekday_tue'),
    _WeekdayOption(DateTime.wednesday, 'weekday_wed'),
    _WeekdayOption(DateTime.thursday, 'weekday_thu'),
    _WeekdayOption(DateTime.friday, 'weekday_fri'),
    _WeekdayOption(DateTime.saturday, 'weekday_sat'),
    _WeekdayOption(DateTime.sunday, 'weekday_sun'),
  ];
}

class _WeekdayOption {
  final int value;
  final String labelKey;

  const _WeekdayOption(this.value, this.labelKey);
}
