import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../providers/animal_provider.dart';
import '../widgets/animal_card.dart';
import 'add_animal_page.dart';
import 'animal_detail_page.dart';

/// Página principal del listado de animales.
class AnimalsPage extends ConsumerWidget {
  const AnimalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animalsAsync = ref.watch(animalsListProvider);

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
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddAnimalPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: animalsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        error: (_, _) =>
            _ErrorState(onRetry: () => ref.invalidate(animalsListProvider)),
        data: (animals) => animals.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSizes.small),
                itemCount: animals.length,
                itemBuilder: (context, index) {
                  final animal = animals[index];
                  return AnimalCard(
                    animalData: animal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnimalDetailPage(animal: animal),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Estado de error con botón de reintento.
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: AppSizes.emptyStateIcon,
            color: appColors.danger,
          ),
          const SizedBox(height: AppSizes.large),
          Text(
            AppStrings.t('load_error'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.small),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(AppStrings.t('retry')),
          ),
        ],
      ),
    );
  }
}

/// Estado vacío cuando no hay animales registrados.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: AppSizes.notificationEmptyIcon,
            color: appColors.inputBorderLight,
          ),
          const SizedBox(height: AppSizes.large),
          Text(
            AppStrings.t('no_animals'),
            style: AppTextStyles.bodyMuted(
              Theme.of(context),
              appColors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSizes.small),
          Text(
            AppStrings.t('add_first'),
            style: AppTextStyles.bodyMuted(
              Theme.of(context),
              appColors.inputBorderLight,
            ),
          ),
        ],
      ),
    );
  }
}