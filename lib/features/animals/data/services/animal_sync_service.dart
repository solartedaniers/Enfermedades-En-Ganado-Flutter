import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_provider.dart';
import '../../presentation/providers/animal_provider.dart';

class AnimalSyncService {
  final WidgetRef ref;
  StreamSubscription? _subscription;

  AnimalSyncService(this.ref);

  void start() {
    final network = ref.read(networkInfoProvider);
    _subscription?.cancel();

    _subscription =
        network.onConnectivityChanged.listen((isConnected) async {
      if (isConnected) {
        try {
          final repo = ref.read(animalRepositoryProvider);
          await repo.syncAnimals();
        } catch (e) {
          // Fallo silencioso
        }
      }
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}