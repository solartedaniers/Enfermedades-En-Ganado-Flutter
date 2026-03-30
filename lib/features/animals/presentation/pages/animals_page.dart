import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../providers/animal_provider.dart';
import '../widgets/animal_card.dart';
import 'add_animal_page.dart';
import 'animal_detail_page.dart';

class AnimalsPage extends ConsumerWidget {
  const AnimalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animalsAsync = ref.watch(animalsListProvider);
    final appColors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('my_animals')),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: AppStrings.t('go_home'),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAnimalPage()),
          );
          ref.invalidate(animalsListProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: animalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: appColors.danger),
              const SizedBox(height: 16),
              Text(
                AppStrings.t('load_error'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(animalsListProvider),
                child: Text(AppStrings.t('retry')),
              ),
            ],
          ),
        ),
        data: (animals) {
          if (animals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 80, color: appColors.inputBorderLight),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.t('no_animals'),
                    style: TextStyle(fontSize: 16, color: appColors.mutedForeground),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.t('add_first'),
                    style: TextStyle(color: appColors.inputBorderLight),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final currentAnimal = animals[index];
              return AnimalCard(
                animalData: currentAnimal,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnimalDetailPage(animal: currentAnimal),
                    ),
                  );
                  ref.invalidate(animalsListProvider);
                },
              );
            },
          );
        },
      ),
    );
  }
}
