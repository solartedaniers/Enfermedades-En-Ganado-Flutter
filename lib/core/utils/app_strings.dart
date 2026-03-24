import 'dart:convert';
import 'package:flutter/services.dart';

class AppStrings {
  static Map<String, dynamic> _strings = {};

  static Future<void> load(String lang) async {
    final json = await rootBundle.loadString('lib/l10n/$lang.json');
    _strings = jsonDecode(json);
  }

  static String t(String key) => _strings[key] ?? key;
}