import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'animal_bottom_sheet_handle.dart';

class AnimalOptionPickerSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selectedValue;
  final ValueChanged<String> onOptionSelected;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;

  const AnimalOptionPickerSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onOptionSelected,
    this.initialChildSize = 0.6,
    this.minChildSize = 0.4,
    this.maxChildSize = 0.9,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const AnimalBottomSheetHandle(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == selectedValue;

                    return ListTile(
                      title: Text(option),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: appColors.chipForeground)
                          : null,
                      tileColor: isSelected ? appColors.selectionBackground : null,
                      onTap: () => onOptionSelected(option),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
