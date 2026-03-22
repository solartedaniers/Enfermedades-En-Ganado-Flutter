import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../animals/data/services/animal_sync_service.dart';
import '../../../animals/presentation/pages/animals_page.dart';
import '../../screens/login_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  AnimalSyncService? syncService;
  String username = "";
  String avatarUrl = "";

  @override
  void initState() {
    super.initState();
    syncService = AnimalSyncService(ref);
    syncService?.start();
    loadProfile();
  }

  @override
  void dispose() {
    syncService?.stop();
    super.dispose();
  }

  Future<void> loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          username = data['username'] ?? "";
          avatarUrl = data['avatar_url'] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar sesión"),
        content: const Text("¿Seguro que deseas cerrar sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Salir"),
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

  void _onMenuTap(String title) {
    switch (title) {
      case "Registrar animal":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnimalsPage()),
        );
        break;

      case "Historial":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnimalsPage()),
        );
        break;

      case "Diagnóstico":
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Próximamente: Diagnóstico IA 🤖")),
        );
        break;

      case "Vacunas":
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Próximamente: Vacunas 💉")),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("AgroVet AI"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green.shade100,
                  backgroundImage:
                      avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 30, color: Colors.green)
                      : null,
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Hola", style: TextStyle(fontSize: 16)),
                    Text(
                      username,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "Panel principal",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(Icons.pets, "Registrar animal"),
                  _buildMenuCard(Icons.health_and_safety, "Diagnóstico"),
                  _buildMenuCard(Icons.history, "Historial"),
                  _buildMenuCard(Icons.vaccines, "Vacunas"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String title) {
    return GestureDetector(
      onTap: () => _onMenuTap(title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.green),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}