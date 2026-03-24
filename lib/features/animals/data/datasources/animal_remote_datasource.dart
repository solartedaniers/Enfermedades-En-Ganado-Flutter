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

    return (response as List)
        .map((json) => AnimalModel.fromJson(json))
        .toList();
  }

  Future<void> insertAnimal(AnimalModel animal) async {
    await _supabase.from('animals').insert(animal.toJson());
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