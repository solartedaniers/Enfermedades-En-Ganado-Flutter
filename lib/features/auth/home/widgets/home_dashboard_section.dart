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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
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
            chartType: _DashboardChartType.bar,
          ),
          const SizedBox(height: 12),
          _DashboardMetricCard(
            title: AppStrings.t('dashboard_locations'),
            items: summary.topLocations,
            chartType: _DashboardChartType.pie,
          ),
          const SizedBox(height: 12),
          _DashboardMetricCard(
            title: AppStrings.t('dashboard_common_diseases'),
            items: summary.topDiseases,
            chartType: _DashboardChartType.pie,
          ),
        ],
      ),
    );
  }
}

enum _DashboardChartType {
  bar,
  pie,
}

class _DashboardMetricCard extends StatelessWidget {
  final String title;
  final List<DashboardMetricItem> items;
  final _DashboardChartType chartType;

  const _DashboardMetricCard({
    required this.title,
    required this.items,
    required this.chartType,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 14 : 16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? appColors.cardDark
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(compact ? 18 : 20),
            boxShadow: [
              BoxShadow(
                color: appColors.lightShadow,
                blurRadius: compact ? 10 : 14,
                offset: Offset(0, compact ? 4 : 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: compact ? 10 : 12),
              if (items.isEmpty)
                Text(
                  AppStrings.t('dashboard_no_records'),
                  style: TextStyle(color: appColors.mutedForeground),
                )
              else
                switch (chartType) {
                  _DashboardChartType.bar => _BarDashboardChart(items: items),
                  _DashboardChartType.pie => _PieDashboardChart(items: items),
                },
            ],
          ),
        );
      },
    );
  }
}

class _BarDashboardChart extends StatelessWidget {
  final List<DashboardMetricItem> items;

  const _BarDashboardChart({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final highestValue = items
        .map((item) => item.value)
        .reduce((current, next) => current > next ? current : next);
    final palette = _chartPalette(colorScheme);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final chartHeight = compact ? 160.0 : 200.0;
        final horizontalGap = compact ? 4.0 : 6.0;

        return SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final color = palette[index % palette.length];
              final ratio = highestValue == 0 ? 0.0 : item.value / highestValue;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : horizontalGap,
                    right: index == items.length - 1 ? 0 : horizontalGap,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${item.value}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: compact ? 6 : 8),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              widthFactor: compact ? 0.8 : 0.72,
                              heightFactor: ratio.clamp(0.0, 1.0),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      color,
                                      color.withValues(alpha: 0.65),
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(14),
                                    bottom: Radius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: appColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _PieDashboardChart extends StatelessWidget {
  final List<DashboardMetricItem> items;

  const _PieDashboardChart({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final palette = _chartPalette(colorScheme);
    final total = items.fold<int>(0, (sum, item) => sum + item.value);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final chartSize = (constraints.maxWidth * (compact ? 0.56 : 0.48))
            .clamp(140.0, 220.0);

        return Column(
          children: [
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: chartSize,
                height: chartSize,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    values: items.map((item) => item.value.toDouble()).toList(),
                    colors: [
                      for (var index = 0; index < items.length; index++)
                        palette[index % palette.length],
                    ],
                    dividerColor: colorScheme.surface,
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 14 : 16),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final color = palette[index % palette.length];
              final percentage = total == 0
                  ? 0
                  : ((item.value / total) * 100).round();

              return Container(
                margin: EdgeInsets.only(bottom: compact ? 8 : 10),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                  vertical: compact ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: compact ? 10 : 12,
                      height: compact ? 10 : 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 10),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    Text(
                      '$percentage%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: appColors.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    Text(
                      '${item.value}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

List<Color> _chartPalette(ColorScheme colorScheme) {
  return [
    colorScheme.primary,
    colorScheme.secondary,
    colorScheme.tertiary,
    colorScheme.primary.withValues(alpha: 0.75),
    colorScheme.secondary.withValues(alpha: 0.75),
    colorScheme.tertiary.withValues(alpha: 0.75),
  ];
}

class _PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color dividerColor;

  const _PieChartPainter({
    required this.values,
    required this.colors,
    required this.dividerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) {
      return;
    }

    final rect = Offset.zero & size;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = dividerColor;

    var startAngle = -90.0 * (3.1415926535897932 / 180.0);
    for (var index = 0; index < values.length; index++) {
      final sweepAngle = (values[index] / total) * 3.1415926535897932 * 2;
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = colors[index % colors.length];

      canvas.drawArc(rect, startAngle, sweepAngle, true, fillPaint);
      canvas.drawArc(rect, startAngle, sweepAngle, true, strokePaint);
      startAngle += sweepAngle;
    }

    final holePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = dividerColor;
    canvas.drawCircle(
      rect.center,
      size.shortestSide * 0.22,
      holePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.colors != colors ||
        oldDelegate.dividerColor != dividerColor;
  }
}
