import 'dart:async';

import '../../../../core/network/network_info.dart';
import '../../../../core/services/offline_auth_service.dart';
import '../../domain/repositories/animal_repository.dart';

/// Servicio de sincronización de animales.
/// Responsabilidad única: escuchar cambios de conectividad y lanzar sincronización
/// cuando la red vuelve a estar disponible.
class AnimalSyncService {
  final AnimalRepository _animalRepository;
  final NetworkInfo _networkInfo;

  StreamSubscription<bool>? _connectivitySubscription;

  AnimalSyncService({
    required AnimalRepository animalRepository,
    required NetworkInfo networkInfo,
  })  : _animalRepository = animalRepository,
        _networkInfo = networkInfo;

  /// Inicia la escucha de conectividad y sincroniza inmediatamente si hay red.
  void start() {
    _connectivitySubscription?.cancel();
    _syncIfConnected();
    _connectivitySubscription =
        _networkInfo.onConnectivityChanged.listen((isConnected) async {
      if (isConnected) await _syncIfConnected();
    });
  }

  /// Sincroniza animales pendientes si hay conexión activa.
  Future<void> _syncIfConnected() async {
    try {
      if (!await _networkInfo.isConnected) return;
      await OfflineAuthService.restoreCloudSessionIfPossible();
      await _animalRepository.syncAnimals();
    } catch (_) {
      // Fallo silencioso; se reintentará en el siguiente evento de conectividad.
    }
  }

  /// Detiene la escucha de conectividad.
  void stop() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}
