import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/animal_provider.dart';
import 'add_animal_page.dart';
import 'package:agrovet_ai/features/medical/presentation/pages/medical_history_page.dart';

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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final animals = snapshot.data ?? [];
          return ListView.builder(
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animal = animals[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (animal.imageUrl != null &&
                          animal.imageUrl!.isNotEmpty)
                      ? NetworkImage(animal.imageUrl!)
                      : null,
                  child: (animal.imageUrl == null || animal.imageUrl!.isEmpty)
                      ? const Icon(Icons.pets)
                      : null,
                ),
                title: Text(animal.name),
                subtitle: Text(animal.breed),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MedicalHistoryPage(
                      animalId: animal.id,
                      animalName: animal.name,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddAnimalPage()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}