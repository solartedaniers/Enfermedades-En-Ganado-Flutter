import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:logger/logger.dart';

import 'features/auth/screens/login_page.dart';
import 'features/auth/home/screens/home_page.dart';

final logger = Logger();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ouxnrcamlloyhcanpbmb.supabase.co',
    anonKey: 'sb_publishable_a49vVecFsuol_HcWdCq_0Q_9SFGJTl1',
  );

  runApp(const AgrovetAI());
}

class AgrovetAI extends StatefulWidget {
  const AgrovetAI({super.key});

  @override
  State<AgrovetAI> createState() => _AgrovetAIState();
}

class _AgrovetAIState extends State<AgrovetAI> {
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  void initDeepLinks() {
    _appLinks.uriLinkStream.listen((uri) {
      if (uri.host == "auth-confirm") {
        logger.i("Cuenta confirmada ✅"); // reemplazo de print
        // Aquí puedes navegar a una pantalla de confirmación
      }
    });

    _appLinks.getInitialLink().then((uri) {
      if (uri != null && uri.host == "auth-confirm") {
        logger.i("Cuenta confirmada desde enlace inicial ✅"); // reemplazo de print
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: session == null ? const LoginPage() : const HomePage(),
    );
  }
}