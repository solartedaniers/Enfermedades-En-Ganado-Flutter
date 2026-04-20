class JsonParser {
  JsonParser._();

  static String? asString(dynamic value) {
    if (value == null) {
      return null;
    }

    return value.toString();
  }

  static int asInt(dynamic value, {int fallback = 0}) {
    if (value is num) {
      return value.toInt();
    }

    return fallback;
  }

  static double? asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return null;
  }

  static List<String> asStringList(dynamic value) {
    if (value is List<dynamic>) {
      return value.map((item) => item.toString()).toList();
    }

    return const [];
  }

  static DateTime asDateTime(dynamic value, {DateTime? fallback}) {
    final resolvedFallback = fallback ?? DateTime.now();

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? resolvedFallback;
    }

    return resolvedFallback;
  }
}
