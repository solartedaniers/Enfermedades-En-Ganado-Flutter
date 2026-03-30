import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/app_strings.dart';

class ConnectivityMessagePresenter {
  const ConnectivityMessagePresenter();

  String resolveMessage(String? customMessage) {
    final normalizedMessage = customMessage?.trim();
    if (normalizedMessage != null && normalizedMessage.isNotEmpty) {
      return normalizedMessage;
    }

    return AppStrings.t('internet_required_default');
  }

  void showOfflineSnackBar(BuildContext context, {String? message}) {
    final appColors = context.appColors;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                resolveMessage(message),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: appColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
