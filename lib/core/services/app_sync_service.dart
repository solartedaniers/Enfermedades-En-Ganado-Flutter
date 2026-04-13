import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/animals/domain/repositories/animal_repository.dart';
import '../../features/auth/services/auth_service.dart';
import 'managed_client_service.dart';
import 'offline_auth_service.dart';
import '../network/network_info.dart';

class AppSyncService {
  final AnimalRepository animalRepository;
  final NetworkInfo networkInfo;
  final ManagedClientService managedClientService;
  final AuthService authService;
  final SupabaseClient supabaseClient;

  StreamSubscription<bool>? _subscription;
  bool _isSyncing = false;

  AppSyncService({
    required this.animalRepository,
    required this.networkInfo,
    required this.managedClientService,
    required this.authService,
    required this.supabaseClient,
  });

  void start() {
    _subscription?.cancel();
    syncIfConnected();
    _subscription = networkInfo.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        syncIfConnected();
      }
    });
  }

  Future<void> syncIfConnected() async {
    if (_isSyncing) {
      return;
    }

    _isSyncing = true;

    try {
      if (!await networkInfo.isConnected) {
        return;
      }

      await authService.syncPendingRegistrations();
      await OfflineAuthService.restoreCloudSessionIfPossible();

      final veterinarianId = supabaseClient.auth.currentUser?.id ??
          (await OfflineAuthService.getSession())['userId'];

      if (veterinarianId != null && veterinarianId.isNotEmpty) {
        await managedClientService.syncToRemote(
          supabaseClient: supabaseClient,
          veterinarianId: veterinarianId,
        );
      }

      await animalRepository.syncAnimals();
    } catch (_) {
      // Dejamos la cola intacta para el siguiente reintento.
    } finally {
      _isSyncing = false;
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
