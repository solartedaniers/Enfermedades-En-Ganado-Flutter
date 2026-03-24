import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_provider.dart';
// 👈 Eliminamos el import de animal_repository_impl.dart porque ya no se usa aquí
import '../../presentation/providers/animal_provider.dart';

class AnimalSyncService {
  final WidgetRef ref;
  StreamSubscription? _subscription;

  AnimalSyncService(this.ref);

  void start() {
    final network = ref.read(networkInfoProvider);

    _subscription?.cancel();

    _subscription = network.onConnectivityChanged.listen((isConnected) async {
      if (isConnected) {
        // Al no usar el "as", Riverpod usa la interfaz genérica y es más limpio
        final repo = ref.read(animalRepositoryProvider);
        await repo.syncAnimals();
      }
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}