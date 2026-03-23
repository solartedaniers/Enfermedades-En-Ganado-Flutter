import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../animals/data/services/animal_sync_service.dart';
import '../../../animals/presentation/pages/animals_page.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../screens/login_page.dart';
import '../../../../core/utils/app_strings.dart';

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
    syncService = AnimalSyncService(ref);
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
        title: Text(AppStrings.t("logout")),
        content: Text(AppStrings.t("logout_confirm")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.t("cancel")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
      case "history":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnimalsPage()),
        );
        break;
      case "diagnosis":
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t("coming_soon_diagnosis"))),
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

    final menuItems = [
      {
        "icon": Icons.pets,
        "key": "register_animal",
        "color": const Color(0xFF43A047),
        "bg": const Color(0xFFE8F5E9),
      },
      {
        "icon": Icons.health_and_safety,
        "key": "diagnosis",
        "color": const Color(0xFF1E88E5),
        "bg": const Color(0xFFE3F2FD),
      },
      {
        "icon": Icons.history,
        "key": "history",
        "color": const Color(0xFF8E24AA),
        "bg": const Color(0xFFF3E5F5),
      },
      {
        "icon": Icons.vaccines,
        "key": "vaccines",
        "color": const Color(0xFFE53935),
        "bg": const Color(0xFFFFEBEE),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t("app_name")),
        elevation: 0, // Más limpio
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
            // --- Header con gradiente (BOTÓN DE PERFIL INTEGRADO) ---
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withValues(alpha: 0.2), // 🔥 Corrección aplicada
                      backgroundImage: profile.avatarUrl != null &&
                              profile.avatarUrl!.isNotEmpty
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child: profile.avatarUrl == null ||
                              profile.avatarUrl!.isEmpty
                          ? const Icon(Icons.person,
                              size: 36, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.t("hello"),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7), // 🔥 Corrección aplicada
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
                          ),
                          const Text(
                            "Toca para configurar perfil",
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          )
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Text(
                AppStrings.t("main_panel"),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Grid de opciones ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: menuItems.map((item) {
                  return _buildMenuCard(
                    icon: item["icon"] as IconData,
                    key: item["key"] as String,
                    color: item["color"] as Color,
                    bg: item["bg"] as Color,
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

  Widget _buildMenuCard({
    required IconData icon,
    required String key,
    required Color color,
    required Color bg,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _onMenuTap(key),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15), // 🔥 Corrección aplicada
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.t(key),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}