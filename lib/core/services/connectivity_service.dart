import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../network/network_info.dart';
import 'connectivity_message_presenter.dart';

class ConnectivityService {
  static final NetworkInfo _networkInfo = NetworkInfo(Connectivity());
  static const ConnectivityMessagePresenter _presenter =
      ConnectivityMessagePresenter();

  static Future<bool> isConnected() async {
    return _networkInfo.isConnected;
  }

  static Future<bool> checkAndNotify(
    BuildContext context, {
    String? message,
  }) async {
    final connected = await isConnected();

    if (!connected && context.mounted) {
      _presenter.showOfflineSnackBar(context, message: message);
    }

    return connected;
  }
}
