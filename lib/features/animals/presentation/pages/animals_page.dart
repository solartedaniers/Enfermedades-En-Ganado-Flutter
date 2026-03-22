import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/animal_provider.dart';
import 'add_animal_page.dart';

class AnimalsPage extends ConsumerWidget {
  const AnimalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animalRepo = ref.watch(animalRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Mis Animales")),
      body: FutureBuilder(
        future: animalRepo.getAnimals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final animals = snapshot.data ?? [];
          return ListView.builder(
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animal = animals[index];
              return ListTile(
                leading: const Icon(Icons.pets),
                title: Text(animal.name),
                subtitle: Text(animal.breed),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAnimalPage())),
        child: const Icon(Icons.add),
      ),
    );
  }
}