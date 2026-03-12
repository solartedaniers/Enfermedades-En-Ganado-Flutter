import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  }

  Future<void> logout() async {

    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/login');

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

          boxShadow: [

            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0,4),
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

                  backgroundImage: avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,

                  child: avatarUrl.isEmpty
                      ? const Icon(Icons.person,size:30)
                      : null,

                ),

                const SizedBox(width:15),

                Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(
                      "Bienvenido",
                      style: TextStyle(fontSize:16),
                    ),

                    Text(
                      username,
                      style: const TextStyle(
                        fontSize:20,
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

            )

          ],

        ),

      ),

    );

  }

}