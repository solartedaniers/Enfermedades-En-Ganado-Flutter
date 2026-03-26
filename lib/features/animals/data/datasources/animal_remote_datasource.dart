import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/animal_model.dart';

class AnimalRemoteDataSource {
  final _supabaseClient = Supabase.instance.client;

  Future<List<AnimalModel>> getAnimals() async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) return [];

    final response = await _supabaseClient
        .from('animals')
        .select()
        .eq('user_id', currentUser.id)
        .order('created_at', ascending: false);

    // Cast seguro de la respuesta remota.
    final responseList = response as List<dynamic>;
    return responseList
        .map((json) => AnimalModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertAnimal(AnimalModel animal) async {
    await _supabaseClient.from('animals').insert(animal.toJson());
  }

  /// Upsert para sincronizacion offline y evitar duplicados al reintentar.
  Future<void> upsertAnimal(AnimalModel animal) async {
    await _supabaseClient
        .from('animals')
        .upsert(animal.toJson(), onConflict: 'id');
  }

  Future<void> updateAnimal(AnimalModel animal) async {
    await _supabaseClient
        .from('animals')
        .update(animal.toJson())
        .eq('id', animal.id);
  }

  Future<void> deleteAnimal(String id) async {
    await _supabaseClient.from('animals').delete().eq('id', id);
  }
}
