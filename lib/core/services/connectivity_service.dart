import 'package:flutter/material.dart';
import '../network/network_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final _networkInfo = NetworkInfo(Connectivity());

  static Future<bool> isConnected() async {
    return await _networkInfo.isConnected;
  }

  /// Muestra snackbar si no hay internet y retorna false
  /// Úsalo antes de cualquier acción que requiera internet
  static Future<bool> checkAndNotify(BuildContext context,
      {String? message}) async {
    final connected = await isConnected();
    if (!connected && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message ??
                      "Necesitas conexión a internet para esta acción",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return connected;
  }
}