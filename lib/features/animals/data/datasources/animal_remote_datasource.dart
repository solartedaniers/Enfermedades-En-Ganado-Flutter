import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/animal_model.dart';

class AnimalRemoteDataSource {
  final _supabase = Supabase.instance.client;

  Future<List<AnimalModel>> getAnimals() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('animals')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    // FIX: cast seguro de la respuesta
    final list = response as List<dynamic>;
    return list
        .map((json) => AnimalModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertAnimal(AnimalModel animal) async {
    await _supabase.from('animals').insert(animal.toJson());
  }

  /// FIX NUEVO: upsert para sincronización offline → evita duplicate key errors
  /// cuando el animal ya fue insertado parcialmente en un intento previo.
  Future<void> upsertAnimal(AnimalModel animal) async {
    await _supabase
        .from('animals')
        .upsert(animal.toJson(), onConflict: 'id');
  }

  Future<void> updateAnimal(AnimalModel animal) async {
    await _supabase
        .from('animals')
        .update(animal.toJson())
        .eq('id', animal.id);
  }

  Future<void> deleteAnimal(String id) async {
    await _supabase.from('animals').delete().eq('id', id);
  }
}