import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/app_strings.dart';
import '../models/home_dashboard_summary.dart';

class HomeDashboardSection extends StatelessWidget {
  final HomeDashboardSummary summary;

  const HomeDashboardSection({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    if (summary.busiestWeekdays.isEmpty &&
        summary.topLocations.isEmpty &&
        summary.topDiseases.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t('dashboard_title'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _DashboardMetricCard(
            title: AppStrings.t('dashboard_activity_days'),
            items: summary.busiestWeekdays,
          ),
          const SizedBox(height: 12),
          _DashboardMetricCard(
            title: AppStrings.t('dashboard_locations'),
            items: summary.topLocations,
          ),
          const SizedBox(height: 12),
          _DashboardMetricCard(
            title: AppStrings.t('dashboard_common_diseases'),
            items: summary.topDiseases,
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  final String title;
  final List<DashboardMetricItem> items;

  const _DashboardMetricCard({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final highestValue = items.isEmpty
        ? 1
        : items
            .map((item) => item.value)
            .reduce((current, next) => current > next ? current : next);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? appColors.cardDark
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: appColors.lightShadow,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              AppStrings.t('dashboard_no_records'),
              style: TextStyle(color: appColors.mutedForeground),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.value}',
                          style: TextStyle(
                            color: appColors.chipForeground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: item.value / highestValue,
                      minHeight: 8,
                      backgroundColor: appColors.selectionBackground,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        appColors.chipForeground,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
