import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/constants/animal_constants.dart';
import '../../domain/entities/animal_entity.dart';
import '../models/animal_remote_model.dart';

class AnimalRemoteDataSource {
  final SupabaseClient _supabaseClient;

  AnimalRemoteDataSource(this._supabaseClient);

  Future<List<AnimalEntity>> getAnimals() async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) return [];

    final response = await _supabaseClient
        .from(AnimalConstants.tableName)
        .select()
        .eq(AnimalConstants.userIdColumn, currentUser.id)
        .order(AnimalConstants.createdAtColumn, ascending: false);

    // Cast seguro de la respuesta remota.
    final responseList = response as List<dynamic>;
    return responseList
        .map((json) => AnimalRemoteModel.fromJson(json as Map<String, dynamic>))
        .map((animal) => animal.toEntity())
        .toList();
  }

  Future<void> insertAnimal(AnimalEntity animal) async {
    await _supabaseClient
        .from(AnimalConstants.tableName)
        .insert(AnimalRemoteModel.fromEntity(animal).toJson());
  }

  /// Upsert para sincronizacion offline y evitar duplicados al reintentar.
  Future<void> upsertAnimal(AnimalEntity animal) async {
    await _supabaseClient
        .from(AnimalConstants.tableName)
        .upsert(AnimalRemoteModel.fromEntity(animal).toJson(), onConflict: 'id');
  }

  Future<void> updateAnimal(AnimalEntity animal) async {
    await _supabaseClient
        .from(AnimalConstants.tableName)
        .update(AnimalRemoteModel.fromEntity(animal).toJson())
        .eq(AnimalConstants.idColumn, animal.id);
  }

  Future<void> deleteAnimal(String id) async {
    await _supabaseClient
        .from(AnimalConstants.tableName)
        .delete()
        .eq(AnimalConstants.idColumn, id);
  }
}
