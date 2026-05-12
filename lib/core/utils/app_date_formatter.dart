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

  // Devuelve solo la hora en formato 12h con AM/PM, ej: "9:33 AM".
  static String shortTime(DateTime value) {
    final hour = value.hour;
    final minute = value.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${_pad(hour12)}:${_pad(minute)} $period';
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');
}
