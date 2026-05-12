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

    // Selector de hora personalizado para garantizar formato 12h con AM/PM
    // sin importar la configuración del sistema o del idioma.
    final time = await showDialog<TimeOfDay>(
      context: context,
      builder: (_) => _TimePickerDialog(
        initialTime: _selectedDate != null
            ? TimeOfDay.fromDateTime(_selectedDate!)
            : TimeOfDay.now(),
      ),
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

// Selector de hora 12h con ruedas de desplazamiento y botones AM/PM.
// Se usa en lugar del showTimePicker nativo para garantizar el formato
// de 12 horas sin depender de la configuración del locale del sistema.
class _TimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const _TimePickerDialog({required this.initialTime});

  @override
  State<_TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  late int _hour;   // 1..12
  late int _minute; // 0..59
  late bool _isAm;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  static const double _itemExtent = 44.0;

  @override
  void initState() {
    super.initState();
    final h = widget.initialTime.hour;
    _isAm = h < 12;
    _hour = h % 12 == 0 ? 12 : h % 12;
    _minute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _hour - 1);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  TimeOfDay get _result {
    final hour24 = _isAm ? (_hour % 12) : (_hour % 12 + 12);
    return TimeOfDay(hour: hour24, minute: _minute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = context.appColors;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return AlertDialog(
      title: Text(AppStrings.t('select_time')),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSizes.medium,
        AppSizes.small,
        AppSizes.medium,
        0,
      ),
      content: SizedBox(
        width: 240,
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Rueda de horas (1-12)
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: _hourController,
                itemExtent: _itemExtent,
                perspective: 0.003,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) =>
                    setState(() => _hour = i + 1),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 12,
                  builder: (_, i) {
                    final selected = _hour == i + 1;
                    return Center(
                      child: Text(
                        '${i + 1}'.padLeft(2, '0'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: selected ? primary : appColors.mutedForeground,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Separador
            Text(
              ':',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Rueda de minutos (00-59)
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: _minuteController,
                itemExtent: _itemExtent,
                perspective: 0.003,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) =>
                    setState(() => _minute = i),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 60,
                  builder: (_, i) {
                    final selected = _minute == i;
                    return Center(
                      child: Text(
                        '$i'.padLeft(2, '0'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: selected ? primary : appColors.mutedForeground,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Botones AM/PM
            const SizedBox(width: AppSizes.medium),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AmPmButton(
                  label: 'AM',
                  selected: _isAm,
                  onTap: () => setState(() => _isAm = true),
                ),
                const SizedBox(height: AppSizes.small),
                _AmPmButton(
                  label: 'PM',
                  selected: !_isAm,
                  onTap: () => setState(() => _isAm = false),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.t('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_result),
          child: Text(AppStrings.t('accept')),
        ),
      ],
    );
  }
}

class _AmPmButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AmPmButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: AppSizes.xSmall),
        decoration: BoxDecoration(
          color: selected ? primary : null,
          border: Border.all(color: primary),
          borderRadius: BorderRadius.circular(AppSizes.small),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? onPrimary : primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
