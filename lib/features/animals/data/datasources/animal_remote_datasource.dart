import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/constants/animal_constants.dart';
import '../../domain/entities/animal_entity.dart';
import '../models/animal_remote_model.dart';

/// Fuente de datos remota para animales usando Supabase.
/// Responsabilidad única: operaciones CRUD contra la tabla remota de animales.
class AnimalRemoteDataSource {
  final SupabaseClient _supabaseClient;

  AnimalRemoteDataSource(this._supabaseClient);

  /// Obtiene todos los animales del usuario autenticado desde Supabase.
  Future<List<AnimalEntity>> getAnimals() async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      throw StateError('Remote session unavailable');
    }

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

  /// Inserta un nuevo animal en Supabase.
  Future<void> insertAnimal(AnimalEntity animal) async {
    await _supabaseClient
        .from(AnimalConstants.tableName)
        .insert(AnimalRemoteModel.fromEntity(animal).toJson());
  }

  /// Upsert para sincronización offline y evitar duplicados al reintentar.
  Future<void> upsertAnimal(AnimalEntity animal) async {
    await _supabaseClient
        .from(AnimalConstants.tableName)
        .upsert(AnimalRemoteModel.fromEntity(animal).toJson(), onConflict: 'id');
  }

  /// Actualiza un animal existente en Supabase.
  Future<void> updateAnimal(AnimalEntity animal) async {
    await _supabaseClient
        .from(AnimalConstants.tableName)
        .update(AnimalRemoteModel.fromEntity(animal).toJson())
        .eq(AnimalConstants.idColumn, animal.id);
  }

  /// Elimina un animal de Supabase por su ID.
  Future<void> deleteAnimal(String id) async {
    await _supabaseClient
        .from(AnimalConstants.tableName)
        .delete()
        .eq(AnimalConstants.idColumn, id);
  }
}
