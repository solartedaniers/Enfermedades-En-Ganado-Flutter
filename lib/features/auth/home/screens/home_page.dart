import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../animals/data/services/animal_sync_service.dart';
import '../../../animals/presentation/pages/animals_page.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
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
                backgroundColor: Colors.red),
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
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AnimalsPage()));
        break;
      case "notifications":
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const NotificationsPage()));
        break;
      case "diagnosis":
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppStrings.t("coming_soon_diagnosis"))),
        );
        break;
      case "vaccines":
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppStrings.t("coming_soon_vaccines"))),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- LISTA ACTUALIZADA ---
    final menuItems = [
      {
        "image": "lib/images/Taureau.webp", // Ruta de tu imagen
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
      {
        "icon": Icons.notifications_active,
        "key": "notifications",
        "color": const Color(0xFFF57C00),
        "bg": const Color(0xFFFFF3E0),
      },
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
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
                      MaterialPageRoute(
                          builder: (_) => const ProfilePage()),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white24,
                            backgroundImage: profile.avatarUrl != null &&
                                    profile.avatarUrl!.isNotEmpty
                                ? NetworkImage(profile.avatarUrl!)
                                : null,
                            child: profile.avatarUrl == null ||
                                    profile.avatarUrl!.isEmpty
                                ? const Icon(Icons.person,
                                    size: 36,
                                    color: Colors.white)
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
                            child: const Icon(Icons.edit,
                                size: 12,
                                color: Color(0xFF2E7D32)),
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
                              color: Colors.white70, fontSize: 14),
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
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
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
                  final i = entry.key;
                  final item = entry.value;
                  return _buildMenuCard(
                    icon: item["icon"] as IconData?, // Ahora es opcional
                    imagePath: item["image"] as String?, // Nueva propiedad
                    key: item["key"] as String,
                    color: item["color"] as Color,
                    bg: item["bg"] as Color,
                    isDark: isDark,
                  ).animate().fadeIn(
                        delay: (200 + i * 80).ms,
                        duration: 400.ms,
                      ).scale(
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

  // --- WIDGET ACTUALIZADO ---
  Widget _buildMenuCard({
    IconData? icon,
    String? imagePath,
    required String key,
    required Color color,
    required Color bg,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => _onMenuTap(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12), // Ajuste de padding para la imagen
              decoration: BoxDecoration(
                color: isDark
                    ? color.withValues(alpha: 0.15)
                    : bg,
                shape: BoxShape.circle,
              ),
              child: imagePath != null 
                ? ClipOval( // Si hay imagen, la mostramos circular
                    child: Image.asset(
                      imagePath,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(icon, size: 32, color: color), // Si no, el icono de siempre
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.t(key),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}