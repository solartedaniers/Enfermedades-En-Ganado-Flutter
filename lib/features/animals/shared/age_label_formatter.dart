import '../../../core/utils/app_strings.dart';
import '../domain/constants/animal_constants.dart';

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

  static List<AnimalAgeOption> buildAgeOptions() {
    return [
      for (int month = 1; month <= 11; month++)
        AnimalAgeOption(
          label: format(month),
          months: month,
        ),
      for (int year = 1; year <= AnimalConstants.maxAgeYears; year++)
        AnimalAgeOption(
          label: format(year * 12),
          months: year * 12,
        ),
    ];
  }
}
