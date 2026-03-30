import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/managed_client_service.dart';
import 'profile_provider.dart';

class ManagedClientState {
  final List<ManagedClientProfile> clients;
  final String? activeClientId;
  final Map<String, String> animalAssignments;

  const ManagedClientState({
    required this.clients,
    required this.activeClientId,
    required this.animalAssignments,
  });

  factory ManagedClientState.empty() {
    return const ManagedClientState(
      clients: [],
      activeClientId: null,
      animalAssignments: {},
    );
  }

  ManagedClientProfile? get activeClient {
    for (final client in clients) {
      if (client.id == activeClientId) {
        return client;
      }
    }

    return null;
  }

  bool get hasActiveClient => activeClient != null;
}

final managedClientServiceProvider = Provider<ManagedClientService>((ref) {
  return const ManagedClientService();
});

final managedClientProvider =
    AsyncNotifierProvider<ManagedClientNotifier, ManagedClientState>(
  ManagedClientNotifier.new,
);

class ManagedClientNotifier extends AsyncNotifier<ManagedClientState> {
  ManagedClientService get _service => ref.read(managedClientServiceProvider);
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<ManagedClientState> build() async {
    final profile = ref.watch(profileProvider);
    final currentUserId = _supabase.auth.currentUser?.id;

    if (currentUserId == null || profile.userType != 'veterinarian') {
      return ManagedClientState.empty();
    }

    final snapshot = await _service.loadSnapshot(currentUserId);
    final resolvedActiveClientId = _resolveActiveClientId(
      clients: snapshot.clients,
      activeClientId: snapshot.activeClientId,
    );

    if (resolvedActiveClientId != snapshot.activeClientId) {
      await _service.setActiveClient(currentUserId, resolvedActiveClientId);
    }

    return ManagedClientState(
      clients: snapshot.clients,
      activeClientId: resolvedActiveClientId,
      animalAssignments: snapshot.animalAssignments,
    );
  }

  Future<void> createClient({
    required String name,
    required String location,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final currentState = state.valueOrNull ?? ManagedClientState.empty();

    if (currentUserId == null) {
      return;
    }

    final newClient = await _service.createClient(
      veterinarianId: currentUserId,
      name: name,
      location: location,
    );

    state = AsyncData(
      ManagedClientState(
        clients: [...currentState.clients, newClient],
        activeClientId: newClient.id,
        animalAssignments: currentState.animalAssignments,
      ),
    );
  }

  Future<void> setActiveClient(String clientId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final currentState = state.valueOrNull;

    if (currentUserId == null || currentState == null) {
      return;
    }

    await _service.setActiveClient(currentUserId, clientId);
    state = AsyncData(
      ManagedClientState(
        clients: currentState.clients,
        activeClientId: clientId,
        animalAssignments: currentState.animalAssignments,
      ),
    );
  }

  Future<void> assignAnimalToActiveClient(String animalId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final currentState = state.valueOrNull;
    final activeClientId = currentState?.activeClientId;

    if (currentUserId == null || currentState == null || activeClientId == null) {
      return;
    }

    await _service.assignAnimalToClient(
      veterinarianId: currentUserId,
      animalId: animalId,
      clientId: activeClientId,
    );

    state = AsyncData(
      ManagedClientState(
        clients: currentState.clients,
        activeClientId: currentState.activeClientId,
        animalAssignments: {
          ...currentState.animalAssignments,
          animalId: activeClientId,
        },
      ),
    );
  }

  String? _resolveActiveClientId({
    required List<ManagedClientProfile> clients,
    required String? activeClientId,
  }) {
    if (clients.isEmpty) {
      return null;
    }

    final hasExistingActiveClient = clients.any(
      (client) => client.id == activeClientId,
    );

    if (hasExistingActiveClient) {
      return activeClientId;
    }

    return clients.first.id;
  }
}
