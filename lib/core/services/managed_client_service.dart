import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ManagedClientProfile {
  final String id;
  final String name;
  final String location;
  final DateTime createdAt;

  const ManagedClientProfile({
    required this.id,
    required this.name,
    required this.location,
    required this.createdAt,
  });

  factory ManagedClientProfile.fromJson(Map<String, dynamic> json) {
    return ManagedClientProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PendingManagedClientDraft {
  final String email;
  final String name;
  final String location;

  const PendingManagedClientDraft({
    required this.email,
    required this.name,
    required this.location,
  });

  factory PendingManagedClientDraft.fromJson(Map<String, dynamic> json) {
    return PendingManagedClientDraft(
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'location': location,
    };
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
  static const String _pendingDraftKey = 'pending_managed_client_draft';

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
    final newClient = ManagedClientProfile(
      id: _uuid.v4(),
      name: name.trim(),
      location: location.trim(),
      createdAt: DateTime.now(),
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

  Future<void> savePendingDraft(PendingManagedClientDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingDraftKey, jsonEncode(draft.toJson()));
  }

  Future<PendingManagedClientDraft?> consumePendingDraft(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final rawDraft = prefs.getString(_pendingDraftKey);

    if (rawDraft == null || rawDraft.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(rawDraft) as Map<String, dynamic>;
    final draft = PendingManagedClientDraft.fromJson(decoded);

    if (draft.email.trim().toLowerCase() != email.trim().toLowerCase()) {
      return null;
    }

    await prefs.remove(_pendingDraftKey);
    return draft;
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
        .map((item) => ManagedClientProfile.fromJson(item as Map<String, dynamic>))
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
      'managed_clients_$veterinarianId';

  String _activeClientKey(String veterinarianId) =>
      'active_managed_client_$veterinarianId';

  String _animalAssignmentsKey(String veterinarianId) =>
      'managed_client_animal_assignments_$veterinarianId';
}
