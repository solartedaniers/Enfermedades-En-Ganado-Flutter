import 'dart:async';

import '../../../../core/services/offline_auth_service.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/animal_repository.dart';

class AnimalSyncService {
  final AnimalRepository animalRepository;
  final NetworkInfo networkInfo;
  StreamSubscription? _subscription;

  AnimalSyncService({
    required this.animalRepository,
    required this.networkInfo,
  });

  void start() {
    _subscription?.cancel();
    _syncIfConnected();
    _subscription =
        networkInfo.onConnectivityChanged.listen((isConnected) async {
      if (isConnected) {
        await _syncIfConnected();
      }
    });
  }

  Future<void> _syncIfConnected() async {
    try {
      if (!await networkInfo.isConnected) {
        return;
      }

      await OfflineAuthService.restoreCloudSessionIfPossible();
      await animalRepository.syncAnimals();
    } catch (_) {
      // Fallo silencioso.
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
