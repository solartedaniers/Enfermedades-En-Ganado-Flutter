import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/animal_model.dart';

class AnimalRemoteDataSource {
  final supabase = Supabase.instance.client;

  /// Obtener animales desde la nube
  Future<List<AnimalModel>> getAnimals() async {
    final response = await supabase
        .from('animals')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => AnimalModel.fromJson(json))
        .toList();
  }

  /// Subir animal a Supabase
  Future<void> insertAnimal(AnimalModel animal) async {
    await supabase.from('animals').insert(animal.toJson());
  }
}