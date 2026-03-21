import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/animal_provider.dart';

class AnimalsPage extends ConsumerWidget {
  const AnimalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animalRepo = ref.watch(animalRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Mis Animales")), // Corregido: AppBar
      body: FutureBuilder(
        future: animalRepo.getAnimals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final animals = snapshot.data ?? [];

          return ListView.builder(
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animal = animals[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (animal.imageUrl != null && animal.imageUrl!.isNotEmpty)
                      ? NetworkImage(animal.imageUrl!)
                      : null,
                  child: (animal.imageUrl == null || animal.imageUrl!.isEmpty)
                      ? const Icon(Icons.pets)
                      : null,
                ),
                title: Text(animal.name),
                // Solo usamos breed ya que species no está en tu modelo
                subtitle: Text(animal.breed), 
              );
            },
          );
        },
      ),
    );
  }
}