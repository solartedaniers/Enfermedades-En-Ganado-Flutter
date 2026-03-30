import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_strings.dart';
import '../../profile/presentation/providers/profile_provider.dart';

enum _AuthPreferenceAction {
  language,
  theme,
}

class AuthPreferencesButton extends ConsumerWidget {
  const AuthPreferencesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_AuthPreferenceAction>(
      icon: const Icon(Icons.more_vert),
      tooltip: AppStrings.t('auth_preferences'),
      onSelected: (action) {
        switch (action) {
          case _AuthPreferenceAction.language:
            _showLanguageSheet(context, ref);
            break;
          case _AuthPreferenceAction.theme:
            _showThemeSheet(context, ref);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_AuthPreferenceAction>(
          value: _AuthPreferenceAction.language,
          child: Text(AppStrings.t('language')),
        ),
        PopupMenuItem<_AuthPreferenceAction>(
          value: _AuthPreferenceAction.theme,
          child: Text(AppStrings.t('app_theme')),
        ),
      ],
    );
  }

  Future<void> _showLanguageSheet(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  AppStrings.t('language'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _PreferenceOptionTile(
                icon: Icons.language,
                title: AppStrings.t('profile_language_spanish'),
                selected: profile.language == 'es',
                onTap: () async {
                  await ref.read(profileProvider.notifier).changeLanguage('es');
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                },
              ),
              _PreferenceOptionTile(
                icon: Icons.language,
                title: AppStrings.t('profile_language_english'),
                selected: profile.language == 'en',
                onTap: () async {
                  await ref.read(profileProvider.notifier).changeLanguage('en');
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showThemeSheet(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  AppStrings.t('app_theme'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _PreferenceOptionTile(
                icon: Icons.brightness_auto,
                title: AppStrings.t('theme_system'),
                selected: profile.themeMode == ThemeMode.system,
                onTap: () async {
                  await ref
                      .read(profileProvider.notifier)
                      .changeTheme(ThemeMode.system);
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                },
              ),
              _PreferenceOptionTile(
                icon: Icons.light_mode,
                title: AppStrings.t('theme_light'),
                selected: profile.themeMode == ThemeMode.light,
                onTap: () async {
                  await ref
                      .read(profileProvider.notifier)
                      .changeTheme(ThemeMode.light);
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                },
              ),
              _PreferenceOptionTile(
                icon: Icons.dark_mode,
                title: AppStrings.t('theme_dark'),
                selected: profile.themeMode == ThemeMode.dark,
                onTap: () async {
                  await ref
                      .read(profileProvider.notifier)
                      .changeTheme(ThemeMode.dark);
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PreferenceOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _PreferenceOptionTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        selected ? Icons.check_circle : icon,
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}
