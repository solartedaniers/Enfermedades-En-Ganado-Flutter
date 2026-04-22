import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_json_keys.dart';
import '../constants/app_storage_keys.dart';

class ManagedClientProfile {
  final String id;
  final String name;
  final String location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const ManagedClientProfile({
    required this.id,
    required this.name,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  factory ManagedClientProfile.fromJson(Map<String, dynamic> json) {
    return ManagedClientProfile(
      id: json[AppJsonKeys.id] as String? ?? '',
      name: json[AppJsonKeys.name] as String? ?? '',
      location: json[AppJsonKeys.location] as String? ?? '',
      createdAt: DateTime.tryParse(json[AppJsonKeys.createdAt] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json[AppJsonKeys.updatedAt] as String? ?? '') ??
          DateTime.now(),
      isSynced: json[AppJsonKeys.isSynced] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppJsonKeys.id: id,
      AppJsonKeys.name: name,
      AppJsonKeys.location: location,
      AppJsonKeys.createdAt: createdAt.toIso8601String(),
      AppJsonKeys.updatedAt: updatedAt.toIso8601String(),
      AppJsonKeys.isSynced: isSynced,
    };
  }

  ManagedClientProfile copyWith({
    String? id,
    String? name,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return ManagedClientProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

class ManagedClientStorageSnapshot {
  final List<ManagedClientProfile> clients;
  final String? activeClientId;
  final Map<String, String> animalAssignments;

  const ManagedClientStorageSnapshot({
    required this.clients,
    required this.activeClientId,
    required this.animalAssignments,
  });
}

class ManagedClientService {
  final Uuid _uuid;

  const ManagedClientService({Uuid uuid = const Uuid()}) : _uuid = uuid;

  Future<ManagedClientStorageSnapshot> loadSnapshot(
    String veterinarianId, {
    SupabaseClient? supabaseClient,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final localClients = _decodeClients(
      prefs.getString(_clientsKey(veterinarianId)),
    );
    final localActiveClientId = prefs.getString(_activeClientKey(veterinarianId));
    final localAnimalAssignments = _decodeAssignments(
      prefs.getString(_animalAssignmentsKey(veterinarianId)),
    );

    if (supabaseClient == null) {
      return ManagedClientStorageSnapshot(
        clients: localClients,
        activeClientId: localActiveClientId,
        animalAssignments: localAnimalAssignments,
      );
    }

    try {
      final remoteClients = await _fetchRemoteClients(
        supabaseClient: supabaseClient,
        veterinarianId: veterinarianId,
      );
      final remoteAnimalAssignments = await _fetchRemoteAnimalAssignments(
        supabaseClient: supabaseClient,
        veterinarianId: veterinarianId,
      );

      final mergedClients = _mergeClients(
        localClients: localClients,
        remoteClients: remoteClients,
      );
      final mergedAnimalAssignments = {
        ...localAnimalAssignments,
        ...remoteAnimalAssignments,
      };
      final resolvedActiveClientId = _resolveActiveClientId(
        clients: mergedClients,
        activeClientId: localActiveClientId,
      );

      await _saveClients(veterinarianId, mergedClients);
      await _saveAnimalAssignments(veterinarianId, mergedAnimalAssignments);

      if (resolvedActiveClientId != localActiveClientId) {
        await setActiveClient(veterinarianId, resolvedActiveClientId);
      }

      return ManagedClientStorageSnapshot(
        clients: mergedClients,
        activeClientId: resolvedActiveClientId,
        animalAssignments: mergedAnimalAssignments,
      );
    } catch (_) {
      // Si falla la lectura remota seguimos operando con la copia local.
    }

    return ManagedClientStorageSnapshot(
      clients: localClients,
      activeClientId: localActiveClientId,
      animalAssignments: localAnimalAssignments,
    );
  }

  Future<ManagedClientProfile> createClient({
    required String veterinarianId,
    required String name,
    required String location,
    SupabaseClient? supabaseClient,
  }) async {
    final now = DateTime.now();
    final newClient = ManagedClientProfile(
      id: _uuid.v4(),
      name: name.trim(),
      location: location.trim(),
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );

    try {
      if (supabaseClient == null) {
        throw StateError('Supabase client unavailable');
      }

      await supabaseClient.from(AppStorageKeys.managedClientsTable).upsert({
        AppJsonKeys.id: newClient.id,
        AppJsonKeys.veterinarianId: veterinarianId,
        AppJsonKeys.name: newClient.name,
        AppJsonKeys.location: newClient.location,
        AppJsonKeys.createdAt: newClient.createdAt.toIso8601String(),
        AppJsonKeys.updatedAt: newClient.updatedAt.toIso8601String(),
      }, onConflict: AppJsonKeys.id);

      final syncedClient = newClient.copyWith(isSynced: true);
      final snapshot = await loadSnapshot(
        veterinarianId,
        supabaseClient: supabaseClient,
      );
      final updatedClients = _upsertLocalClient(snapshot.clients, syncedClient);

      await _saveClients(veterinarianId, updatedClients);
      await setActiveClient(veterinarianId, syncedClient.id);

      return syncedClient;
    } catch (_) {
      final snapshot = await loadSnapshot(veterinarianId);
      final updatedClients = _upsertLocalClient(snapshot.clients, newClient);

      await _saveClients(veterinarianId, updatedClients);
      await setActiveClient(veterinarianId, newClient.id);

      return newClient;
    }
  }

  Future<void> setActiveClient(String veterinarianId, String? clientId) async {
    final prefs = await SharedPreferences.getInstance();

    if (clientId == null || clientId.isEmpty) {
      await prefs.remove(_activeClientKey(veterinarianId));
      return;
    }

    await prefs.setString(_activeClientKey(veterinarianId), clientId);
  }

  Future<ManagedClientProfile> updateClient({
    required String veterinarianId,
    required String clientId,
    required String name,
    required String location,
    SupabaseClient? supabaseClient,
  }) async {
    final snapshot = await loadSnapshot(veterinarianId);
    final existingClient = _findClient(snapshot.clients, clientId);

    if (existingClient == null) {
      throw StateError('Managed client not found');
    }

    final updatedClient = existingClient.copyWith(
      name: name.trim(),
      location: location.trim(),
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    try {
      if (supabaseClient == null) {
        throw StateError('Supabase client unavailable');
      }

      await supabaseClient
          .from(AppStorageKeys.managedClientsTable)
          .update({
            AppJsonKeys.name: updatedClient.name,
            AppJsonKeys.location: updatedClient.location,
            AppJsonKeys.updatedAt: updatedClient.updatedAt.toIso8601String(),
          })
          .eq(AppJsonKeys.id, clientId)
          .eq(AppJsonKeys.veterinarianId, veterinarianId);

      final syncedClient = updatedClient.copyWith(isSynced: true);
      final updatedClients = _upsertLocalClient(snapshot.clients, syncedClient);
      await _saveClients(veterinarianId, updatedClients);

      return syncedClient;
    } catch (_) {
      final updatedClients = _upsertLocalClient(snapshot.clients, updatedClient);
      await _saveClients(veterinarianId, updatedClients);

      return updatedClient;
    }
  }

  Future<String?> deleteClient({
    required String veterinarianId,
    required String clientId,
    SupabaseClient? supabaseClient,
  }) async {
    final snapshot = await loadSnapshot(veterinarianId);
    final remainingClients = snapshot.clients
        .where((client) => client.id != clientId)
        .toList();
    final cleanedAssignments = Map<String, String>.from(snapshot.animalAssignments)
      ..removeWhere((_, assignedClientId) => assignedClientId == clientId);
    final nextActiveClientId = _resolveActiveClientId(
      clients: remainingClients,
      activeClientId: snapshot.activeClientId == clientId
          ? null
          : snapshot.activeClientId,
    );

    await _saveClients(veterinarianId, remainingClients);
    await _saveAnimalAssignments(veterinarianId, cleanedAssignments);
    await setActiveClient(veterinarianId, nextActiveClientId);

    if (supabaseClient == null) {
      return nextActiveClientId;
    }

    try {
      await supabaseClient
          .from(AppStorageKeys.managedClientAnimalsTable)
          .delete()
          .eq(AppJsonKeys.veterinarianId, veterinarianId)
          .eq(AppJsonKeys.clientId, clientId);

      await supabaseClient
          .from(AppStorageKeys.managedClientsTable)
          .delete()
          .eq(AppJsonKeys.id, clientId)
          .eq(AppJsonKeys.veterinarianId, veterinarianId);
    } catch (_) {
      // Si falla la eliminacion remota mantenemos la copia local actualizada.
    }

    return nextActiveClientId;
  }

  Future<void> assignAnimalToClient({
    required String veterinarianId,
    required String animalId,
    required String clientId,
    SupabaseClient? supabaseClient,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final assignments = _decodeAssignments(
      prefs.getString(_animalAssignmentsKey(veterinarianId)),
    );

    assignments[animalId] = clientId;

    await prefs.setString(
      _animalAssignmentsKey(veterinarianId),
      jsonEncode(assignments),
    );

    if (supabaseClient == null) {
      return;
    }

    try {
      await supabaseClient.from(AppStorageKeys.managedClientAnimalsTable).upsert({
        AppJsonKeys.veterinarianId: veterinarianId,
        AppJsonKeys.animalId: animalId,
        AppJsonKeys.clientId: clientId,
        AppJsonKeys.updatedAt: DateTime.now().toIso8601String(),
      }, onConflict: '${AppJsonKeys.veterinarianId},${AppJsonKeys.animalId}');
    } catch (_) {
      // La asignacion queda local para sincronizarse despues.
    }
  }

  Future<void> removeAnimalAssignment({
    required String veterinarianId,
    required String animalId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final assignments = _decodeAssignments(
      prefs.getString(_animalAssignmentsKey(veterinarianId)),
    );

    assignments.remove(animalId);

    await prefs.setString(
      _animalAssignmentsKey(veterinarianId),
      jsonEncode(assignments),
    );
  }

  Future<void> syncToRemote({
    required SupabaseClient supabaseClient,
    required String veterinarianId,
  }) async {
    final snapshot = await loadSnapshot(veterinarianId);

    if (snapshot.clients.isNotEmpty) {
      final payload = snapshot.clients
          .map(
            (client) => {
              AppJsonKeys.id: client.id,
              AppJsonKeys.veterinarianId: veterinarianId,
              AppJsonKeys.name: client.name,
              AppJsonKeys.location: client.location,
              AppJsonKeys.createdAt: client.createdAt.toIso8601String(),
              AppJsonKeys.updatedAt: client.updatedAt.toIso8601String(),
            },
          )
          .toList();

      await supabaseClient
          .from(AppStorageKeys.managedClientsTable)
          .upsert(payload, onConflict: AppJsonKeys.id);

      final syncedClients = snapshot.clients
          .map((client) => client.copyWith(isSynced: true))
          .toList();
      await _saveClients(veterinarianId, syncedClients);
    }

    if (snapshot.animalAssignments.isNotEmpty) {
      final assignmentPayload = snapshot.animalAssignments.entries
          .map(
            (entry) => {
              AppJsonKeys.veterinarianId: veterinarianId,
              AppJsonKeys.animalId: entry.key,
              AppJsonKeys.clientId: entry.value,
              AppJsonKeys.updatedAt: DateTime.now().toIso8601String(),
            },
          )
          .toList();

      await supabaseClient
          .from(AppStorageKeys.managedClientAnimalsTable)
          .upsert(
            assignmentPayload,
            onConflict:
                '${AppJsonKeys.veterinarianId},${AppJsonKeys.animalId}',
          );
    }
  }

  Future<List<ManagedClientProfile>> _fetchRemoteClients({
    required SupabaseClient supabaseClient,
    required String veterinarianId,
  }) async {
    final response = await supabaseClient
        .from(AppStorageKeys.managedClientsTable)
        .select()
        .eq(AppJsonKeys.veterinarianId, veterinarianId)
        .order(AppJsonKeys.createdAt);

    return (response as List<dynamic>)
        .map((item) => item as Map<String, dynamic>)
        .map(
          (item) => ManagedClientProfile.fromJson({
            ...item,
            AppJsonKeys.isSynced: true,
          }),
        )
        .toList();
  }

  Future<Map<String, String>> _fetchRemoteAnimalAssignments({
    required SupabaseClient supabaseClient,
    required String veterinarianId,
  }) async {
    final response = await supabaseClient
        .from(AppStorageKeys.managedClientAnimalsTable)
        .select('${AppJsonKeys.animalId}, ${AppJsonKeys.clientId}')
        .eq(AppJsonKeys.veterinarianId, veterinarianId);

    final rows = response as List<dynamic>;
    final assignments = <String, String>{};

    for (final row in rows) {
      final data = row as Map<String, dynamic>;
      final animalId = data[AppJsonKeys.animalId]?.toString();
      final clientId = data[AppJsonKeys.clientId]?.toString();

      if (animalId == null ||
          animalId.isEmpty ||
          clientId == null ||
          clientId.isEmpty) {
        continue;
      }

      assignments[animalId] = clientId;
    }

    return assignments;
  }

  List<ManagedClientProfile> _mergeClients({
    required List<ManagedClientProfile> localClients,
    required List<ManagedClientProfile> remoteClients,
  }) {
    final mergedById = <String, ManagedClientProfile>{
      for (final client in remoteClients) client.id: client,
    };

    for (final client in localClients) {
      final remoteClient = mergedById[client.id];
      if (remoteClient == null || client.updatedAt.isAfter(remoteClient.updatedAt)) {
        mergedById[client.id] = client;
      }
    }

    final mergedClients = mergedById.values.toList()
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));

    return mergedClients;
  }

  List<ManagedClientProfile> _upsertLocalClient(
    List<ManagedClientProfile> clients,
    ManagedClientProfile client,
  ) {
    final updatedClients = [...clients];
    final existingIndex = updatedClients.indexWhere((item) => item.id == client.id);

    if (existingIndex == -1) {
      updatedClients.add(client);
    } else {
      updatedClients[existingIndex] = client;
    }

    updatedClients.sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return updatedClients;
  }

  ManagedClientProfile? _findClient(
    List<ManagedClientProfile> clients,
    String clientId,
  ) {
    for (final client in clients) {
      if (client.id == clientId) {
        return client;
      }
    }

    return null;
  }

  Future<void> _saveAnimalAssignments(
    String veterinarianId,
    Map<String, String> assignments,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _animalAssignmentsKey(veterinarianId),
      jsonEncode(assignments),
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

  Future<void> _saveClients(
    String veterinarianId,
    List<ManagedClientProfile> clients,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = clients.map((client) => client.toJson()).toList();

    await prefs.setString(_clientsKey(veterinarianId), jsonEncode(payload));
  }

  List<ManagedClientProfile> _decodeClients(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawValue) as List<dynamic>;
    return decoded
        .map(
          (item) => ManagedClientProfile.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Map<String, String> _decodeAssignments(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(rawValue) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }

  String _clientsKey(String veterinarianId) =>
      '${AppStorageKeys.managedClientsStoragePrefix}$veterinarianId';

  String _activeClientKey(String veterinarianId) =>
      '${AppStorageKeys.activeManagedClientStoragePrefix}$veterinarianId';

  String _animalAssignmentsKey(String veterinarianId) =>
      '${AppStorageKeys.managedClientAssignmentsStoragePrefix}$veterinarianId';
}
