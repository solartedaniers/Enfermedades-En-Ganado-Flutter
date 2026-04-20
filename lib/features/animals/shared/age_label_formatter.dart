import '../../../core/utils/app_strings.dart';

class AgeLabelFormatter {
  static String format(int months) {
    if (months < 1) {
      return AppStrings.t('newborn');
    }

    if (months < 12) {
      final unitKey = months == 1 ? 'month' : 'months';
      return '$months ${AppStrings.t(unitKey)}';
    }

    final years = months ~/ 12;
    final unitKey = years == 1 ? 'year' : 'years';
    return '$years ${AppStrings.t(unitKey)}';
  }
}
