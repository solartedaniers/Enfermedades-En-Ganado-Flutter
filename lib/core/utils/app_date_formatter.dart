import 'app_strings.dart';

class AppDateFormatter {
  AppDateFormatter._();

  static String shortDate(DateTime value) {
    if (AppStrings.isEnglish) {
      return '${_pad(value.month)}/${_pad(value.day)}/${value.year}';
    }

    return '${_pad(value.day)}/${_pad(value.month)}/${value.year}';
  }

  static String shortDateTime(DateTime value) {
    return '${shortDate(value)} ${_pad(value.hour)}:${_pad(value.minute)}';
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');
}
