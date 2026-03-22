import 'package:hive/hive.dart';
import '../models/animal_model.dart';

class AnimalLocalDataSource {
  static const String boxName = 'animals_box';

  Future<Box<AnimalModel>> _openBox() async {
    return await Hive.openBox<AnimalModel>(boxName);
  }

  /// Guardar animal localmente
  Future<void> saveAnimal(AnimalModel animal) async {
    final box = await _openBox();
    final animalModel = AnimalModel(
      id: animal.id,
      userId: animal.userId, // 👈 Campo obligatorio
      name: animal.name,
      breed: animal.breed,
      age: animal.age,
      symptoms: animal.symptoms,
      createdAt: animal.createdAt,
      updatedAt: animal.updatedAt,
      weight: animal.weight,
      temperature: animal.temperature,
      imageUrl: animal.imageUrl,
      isSynced: false, // 👈 Se guarda inicialmente como no sincronizado
    );
    await box.put(animal.id, animalModel);
  }

  /// Obtener todos los animales
  Future<List<AnimalModel>> getAnimals() async {
    final box = await _openBox();
    return box.values.toList();
  }

  /// Obtener no sincronizados
  Future<List<AnimalModel>> getUnsyncedAnimals() async {
    final box = await _openBox();
    return box.values.where((a) => !a.isSynced).toList();
  }

  /// Marcar como sincronizado
  Future<void> markAsSynced(String id) async {
    final box = await _openBox();
    final animal = box.get(id);

    if (animal != null) {
      final updated = AnimalModel(
        id: animal.id,
        userId: animal.userId, // 👈 Mantener el userId
        name: animal.name,
        breed: animal.breed,
        age: animal.age,
        symptoms: animal.symptoms,
        createdAt: animal.createdAt,
        updatedAt: DateTime.now(),
        weight: animal.weight,
        temperature: animal.temperature,
        imageUrl: animal.imageUrl,
        isSynced: true, // 👈 Ahora marcado como sincronizado
      );

      await box.put(id, updated);
    }
  }
}