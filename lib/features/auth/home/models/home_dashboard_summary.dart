class DashboardMetricItem {
  final String label;
  final int value;

  const DashboardMetricItem({
    required this.label,
    required this.value,
  });
}

class HomeDashboardSummary {
  final List<DashboardMetricItem> busiestWeekdays;
  final List<DashboardMetricItem> topLocations;
  final List<DashboardMetricItem> topDiseases;

  const HomeDashboardSummary({
    required this.busiestWeekdays,
    required this.topLocations,
    required this.topDiseases,
  });

  factory HomeDashboardSummary.empty() {
    return const HomeDashboardSummary(
      busiestWeekdays: [],
      topLocations: [],
      topDiseases: [],
    );
  }
}
