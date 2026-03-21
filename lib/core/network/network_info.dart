import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  final Connectivity connectivity;

  NetworkInfo(this.connectivity);

  Stream<bool> get onConnectivityChanged {
    return connectivity.onConnectivityChanged.map(
      // 'results' es una List<ConnectivityResult>
      (results) => !results.contains(ConnectivityResult.none),
    );
  }

  Future<bool> get isConnected async {
    final results = await connectivity.checkConnectivity();
    // Verificamos si en la lista NO está el estado 'none'
    return !results.contains(ConnectivityResult.none);
  }
}