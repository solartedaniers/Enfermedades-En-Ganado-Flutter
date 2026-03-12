import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final SupabaseClient supabase = Supabase.instance.client;

  String username = "";
  String avatarUrl = "";

  @override
  void initState() {
    super.initState();
    loadProfile();
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

      setState(() {
        username = data['username'] ?? "";
        avatarUrl = data['avatar_url'] ?? "";
      });

    } catch (e) {

      debugPrint("Error loading profile: $e");

    }

  }

  Future<void> logout() async {

    final confirm = await showDialog(

      context: context,

      builder: (context) {

        return AlertDialog(

          title: const Text("Cerrar sesión"),

          content: const Text("¿Seguro que deseas cerrar sesión?"),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(context,false);

              },

              child: const Text("Cancelar"),

            ),

            TextButton(

              onPressed: () {

                Navigator.pop(context,true);

              },

              child: const Text("Salir"),

            ),

          ],

        );

      },

    );

    if (confirm != true) return;

    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(

      context,

      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),

      (route) => false,

    );

  }

  Widget buildMenuCard({

    required IconData icon,
    required String title,
    required VoidCallback onTap,

  }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        decoration: BoxDecoration(

          color: Colors.white,
          borderRadius: BorderRadius.circular(16),

          boxShadow: const [

            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0,4),
            )

          ],

        ),

        padding: const EdgeInsets.all(20),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(icon,size:40,color:Colors.green),

            const SizedBox(height:10),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold
              ),
            )

          ],

        ),

      ),

    );

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
            tooltip: "Cerrar sesión",

            onPressed: logout,

          )

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

                  backgroundImage: avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,

                  child: avatarUrl.isEmpty
                      ? const Icon(Icons.person,size:30,color:Colors.green)
                      : null,

                ),

                const SizedBox(width:15),

                Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(
                      "Hola",
                      style: TextStyle(fontSize:16),
                    ),

                    Text(
                      username,
                      style: const TextStyle(
                        fontSize:22,
                        fontWeight: FontWeight.bold
                      ),
                    )

                  ],

                )

              ],

            ),

            const SizedBox(height:30),

            const Text(
              "Panel principal",
              style: TextStyle(
                fontSize:20,
                fontWeight: FontWeight.bold
              ),
            ),

            const SizedBox(height:20),

            Expanded(

              child: GridView.count(

                crossAxisCount: 2,

                crossAxisSpacing: 16,
                mainAxisSpacing: 16,

                children: [

                  buildMenuCard(
                    icon: Icons.pets,
                    title: "Registrar animal",
                    onTap: () {},
                  ),

                  buildMenuCard(
                    icon: Icons.health_and_safety,
                    title: "Diagnóstico",
                    onTap: () {},
                  ),

                  buildMenuCard(
                    icon: Icons.history,
                    title: "Historial",
                    onTap: () {},
                  ),

                  buildMenuCard(
                    icon: Icons.vaccines,
                    title: "Vacunas",
                    onTap: () {},
                  ),

                ],

              ),

            ),

            const SizedBox(height:10),

            SizedBox(

              width: double.infinity,

              child: ElevatedButton.icon(

                icon: const Icon(Icons.logout),

                label: const Text("Cerrar sesión"),

                style: ElevatedButton.styleFrom(

                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.all(14),

                ),

                onPressed: logout,

              ),

            ),

          ],

        ),

      ),

    );

  }

}