import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/screens/login_page.dart';
import 'features/auth/home/screens/home_page.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ouxnrcamlloyhcanpbmb.supabase.co',
    anonKey: 'sb_publishable_a49vVecFsuol_HcWdCq_0Q_9SFGJTl1',
  );

  runApp(const AgrovetAI());
}

class AgrovetAI extends StatelessWidget {
  const AgrovetAI({super.key});

  @override
  Widget build(BuildContext context) {

    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: session == null
          ? const LoginPage()
          : const HomePage(),
    );
  }
}