import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/network_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../animals/data/services/animal_sync_service.dart';
import '../../../animals/presentation/pages/add_animal_page.dart';
import '../../../animals/presentation/pages/animals_page.dart';
import '../../../animals/presentation/providers/animal_provider.dart';
import '../../../diagnosis/screens/scanner_screen.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../screens/login_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  AnimalSyncService? syncService;

  @override
  void initState() {
    super.initState();
    syncService = AnimalSyncService(
      animalRepository: ref.read(animalRepositoryProvider),
      networkInfo: ref.read(networkInfoProvider),
    );
    syncService?.start();
  }

  @override
  void dispose() {
    syncService?.stop();
    super.dispose();
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppStrings.t("logout")),
        content: Text(AppStrings.t("logout_confirm")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.t("cancel")),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appColors.danger,
            ),
            child: Text(AppStrings.t("exit")),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    syncService?.stop();
    await supabase.auth.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _onMenuTap(String key) {
    switch (key) {
      case "register_animal":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddAnimalPage()),
        );
        break;
      case "history":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnimalsPage()),
        );
        break;
      case "notifications":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        );
        break;
      case "diagnosis":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScannerScreen()),
        );
        break;
      case "vaccines":
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t("coming_soon_vaccines"))),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = context.appColors;
    final isDark = theme.brightness == Brightness.dark;

    final menuItems = [
      _HomeMenuItem(
        keyName: "register_animal",
        imagePath: "lib/images/Taureau.webp",
        foregroundColor: appColors.success,
        backgroundColor: appColors.selectionBackground,
      ),
      _HomeMenuItem(
        keyName: "diagnosis",
        icon: Icons.health_and_safety,
        foregroundColor: colorScheme.secondary,
        backgroundColor: colorScheme.secondaryContainer,
      ),
      _HomeMenuItem(
        keyName: "history",
        icon: Icons.pets,
        foregroundColor: colorScheme.tertiary,
        backgroundColor: colorScheme.tertiaryContainer,
      ),
      _HomeMenuItem(
        keyName: "vaccines",
        icon: Icons.vaccines,
        foregroundColor: appColors.danger,
        backgroundColor: colorScheme.errorContainer,
      ),
      _HomeMenuItem(
        keyName: "notifications",
        icon: Icons.alarm,
        foregroundColor: appColors.warning,
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t("app_name")),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [appColors.heroGradientStart, appColors.heroGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: appColors.whiteOverlay,
                            backgroundImage: profile.avatarUrl != null &&
                                    profile.avatarUrl!.isNotEmpty
                                ? NetworkImage(profile.avatarUrl!)
                                : null,
                            child: profile.avatarUrl == null ||
                                    profile.avatarUrl!.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 36,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 12,
                              color: appColors.chipForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t("hello"),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          profile.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Text(
                AppStrings.t("main_panel"),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: menuItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return _MenuCard(
                    item: item,
                    isDark: isDark,
                    onTap: () => _onMenuTap(item.keyName),
                  )
                      .animate()
                      .fadeIn(delay: (200 + index * 80).ms, duration: 400.ms)
                      .scale(
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1, 1),
                      );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HomeMenuItem {
  final String keyName;
  final IconData? icon;
  final String? imagePath;
  final Color foregroundColor;
  final Color backgroundColor;

  const _HomeMenuItem({
    required this.keyName,
    required this.foregroundColor,
    required this.backgroundColor,
    this.icon,
    this.imagePath,
  });
}

class _MenuCard extends StatelessWidget {
  final _HomeMenuItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _MenuCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isDark ? appColors.cardDark : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: item.foregroundColor.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? item.foregroundColor.withValues(alpha: 0.15)
                    : item.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: item.imagePath != null
                  ? ClipOval(
                      child: Image.asset(
                        item.imagePath!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(item.icon, size: 32, color: item.foregroundColor),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.t(item.keyName),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : appColors.subduedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
