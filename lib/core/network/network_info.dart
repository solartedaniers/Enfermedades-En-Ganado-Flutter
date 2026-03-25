import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importa Riverpod

// 1. Define el Provider aquí para que sea accesible globalmente
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfo(Connectivity());
});

class NetworkInfo {
  final Connectivity connectivity;

  NetworkInfo(this.connectivity);

  Stream<bool> get onConnectivityChanged {
    return connectivity.onConnectivityChanged.map(
      (results) => !results.contains(ConnectivityResult.none),
    );
  }

  Future<bool> get isConnected async {
    final results = await connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}