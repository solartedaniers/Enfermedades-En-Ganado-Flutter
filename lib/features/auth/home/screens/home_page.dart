import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String _username = "Cargando...";
  String _avatarUrl = "";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Carga de datos de perfil desde Supabase
  Future<void> _loadProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase.from('profiles').select().eq('id', user.id).single();
      setState(() {
        _username = data['username'] ?? "Usuario";
        _avatarUrl = data['avatar_url'] ?? "";
      });
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  // Lógica de cierre de sesión con diálogo de confirmación
  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar sesión"),
        content: const Text("¿Seguro que deseas salir de AgroVet AI?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCELAR")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("SALIR", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => const LoginPage()), 
        (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0), // Fondo naturaleza
      appBar: AppBar(
        title: const Text("Panel AgroVet", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Sección de Bienvenida (Profile Header)
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.green.shade100,
                  backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                  child: _avatarUrl.isEmpty ? const Icon(Icons.person, size: 35, color: Colors.green) : null,
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Hola,", style: TextStyle(color: Colors.black54, fontSize: 16)),
                    Text(_username, style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ],
            ),
          ),
          
          // Grid de Acciones Principales
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(Icons.pets, "Registrar Animal", Colors.green, () {}),
                _buildActionCard(Icons.biotech_rounded, "Diagnóstico AI", Colors.blue, () {}),
                _buildActionCard(Icons.history_rounded, "Historial", Colors.orange, () {}),
                _buildActionCard(Icons.vaccines_rounded, "Vacunación", Colors.teal, () {}),
              ],
            ),
          ),
          
          // Botón de salida elegante
          Padding(
            padding: const EdgeInsets.all(25),
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text("CERRAR SESIÓN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                side: const BorderSide(color: Colors.red, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget reutilizable para las tarjetas del menú
  Widget _buildActionCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}