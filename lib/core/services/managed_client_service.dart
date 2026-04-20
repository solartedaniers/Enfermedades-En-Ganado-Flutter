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

  Future<ManagedClientStorageSnapshot> loadSnapshot(String veterinarianId) async {
    final prefs = await SharedPreferences.getInstance();
    final clients = _decodeClients(
      prefs.getString(_clientsKey(veterinarianId)),
    );
    final activeClientId = prefs.getString(_activeClientKey(veterinarianId));
    final animalAssignments = _decodeAssignments(
      prefs.getString(_animalAssignmentsKey(veterinarianId)),
    );

    return ManagedClientStorageSnapshot(
      clients: clients,
      activeClientId: activeClientId,
      animalAssignments: animalAssignments,
    );
  }

  Future<ManagedClientProfile> createClient({
    required String veterinarianId,
    required String name,
    required String location,
  }) async {
    final snapshot = await loadSnapshot(veterinarianId);
    final now = DateTime.now();
    final newClient = ManagedClientProfile(
      id: _uuid.v4(),
      name: name.trim(),
      location: location.trim(),
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );
    final updatedClients = [...snapshot.clients, newClient];

    await _saveClients(veterinarianId, updatedClients);
    await setActiveClient(veterinarianId, newClient.id);

    return newClient;
  }

  Future<void> setActiveClient(String veterinarianId, String? clientId) async {
    final prefs = await SharedPreferences.getInstance();

    if (clientId == null || clientId.isEmpty) {
      await prefs.remove(_activeClientKey(veterinarianId));
      return;
    }

    await prefs.setString(_activeClientKey(veterinarianId), clientId);
  }

  Future<void> assignAnimalToClient({
    required String veterinarianId,
    required String animalId,
    required String clientId,
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
