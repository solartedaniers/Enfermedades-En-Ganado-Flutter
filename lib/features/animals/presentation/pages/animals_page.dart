import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/animal_provider.dart';
import '../widgets/animal_card.dart';
import 'add_animal_page.dart';
import 'animal_detail_page.dart';

class AnimalsPage extends ConsumerWidget {
  const AnimalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animalRepo = ref.watch(animalRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Mis Animales")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAnimalPage()),
          );
          ref.invalidate(animalRepositoryProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: animalRepo.getAnimals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text("Error al cargar datos",
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(animalRepositoryProvider),
                    child: const Text("Reintentar"),
                  ),
                ],
              ),
            );
          }

          final animals = snapshot.data ?? [];

          if (animals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No tienes animales registrados",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Toca el botón + para agregar uno",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animal = animals[index];
              return AnimalCard(
                animal: animal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnimalDetailPage(animal: animal),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}