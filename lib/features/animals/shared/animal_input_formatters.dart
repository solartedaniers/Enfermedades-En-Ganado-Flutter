import 'package:flutter/services.dart';

class AnimalInputFormatters {
  AnimalInputFormatters._();

  static final TextInputFormatter name = FilteringTextInputFormatter.allow(
    RegExp(r"[a-zA-Z\u00C0-\u00FF0-9 ]"),
  );

  static final TextInputFormatter decimal = FilteringTextInputFormatter.allow(
    RegExp(r'[\d.,]'),
  );
}
