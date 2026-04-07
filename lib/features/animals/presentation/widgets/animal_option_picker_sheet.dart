import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'animal_bottom_sheet_handle.dart';

class AnimalOptionItem {
  final String value;
  final String label;

  const AnimalOptionItem({
    required this.value,
    required this.label,
  });
}

class AnimalOptionPickerSheet extends StatelessWidget {
  final String title;
  final List<AnimalOptionItem> options;
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
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.xxLarge),
            ),
          ),
          child: Column(
            children: [
              const AnimalBottomSheetHandle(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.xLarge,
                  vertical: AppSizes.small,
                ),
                child: Text(
                  title,
                  style: AppTextStyles.sectionTitle(Theme.of(context)),
                ),
              ),
              const Divider(height: AppSizes.xSmall),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option.value == selectedValue;

                    return ListTile(
                      title: Text(option.label),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: appColors.chipForeground)
                          : null,
                      tileColor: isSelected ? appColors.selectionBackground : null,
                      onTap: () => onOptionSelected(option.value),
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
