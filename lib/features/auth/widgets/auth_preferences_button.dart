import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_strings.dart';
import '../../profile/presentation/providers/profile_provider.dart';

class AuthPreferencesButton extends ConsumerWidget {
  const AuthPreferencesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final nextLanguage = profile.language == 'es' ? 'en' : 'es';
    final nextLanguageLabel = nextLanguage.toUpperCase();

    return IconButton(
      onPressed: () async {
        await ref.read(profileProvider.notifier).changeLanguage(nextLanguage);
      },
      tooltip: AppStrings.t('language'),
      icon: Badge(
        label: Text(nextLanguageLabel),
        backgroundColor: colorScheme.primary,
        textColor: colorScheme.onPrimary,
        child: Icon(
          Icons.language,
          color: colorScheme.onSurface,
        ),
      ),
      color: colorScheme.onSurface,
    );
  }
}
