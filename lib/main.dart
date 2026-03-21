import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:logger/logger.dart';
import 'package:hive_flutter/hive_flutter.dart';   // 👈 Import Hive
import 'features/animals/data/models/animal_model.dart'; // 👈 Tu modelo Hive
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 Import Riverpod

import 'features/auth/screens/login_page.dart';
import 'features/auth/home/screens/home_page.dart';
import 'features/auth/screens/reset_password_page.dart';

final logger = Logger();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Hive
  await Hive.initFlutter();
  Hive.registerAdapter(AnimalModelAdapter()); // 👈 Registrar tu adapter

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://ouxnrcamlloyhcanpbmb.supabase.co',
    anonKey: 'sb_publishable_a49vVecFsuol_HcWdCq_0Q_9SFGJTl1',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(
    const ProviderScope(   // 👈 Aquí envuelves tu app
      child: AgrovetAI(),
    ),
  );
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
    _appLinks.uriLinkStream.listen((uri) async {
      logger.i("DeepLink recibido: $uri");
      await _handleDeepLink(uri);
    });

    _appLinks.getInitialLink().then((uri) async {
      if (uri != null) {
        logger.i("DeepLink inicial: $uri");
        await _handleDeepLink(uri);
      }
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);

      if (uri.host == "auth-confirm") {
        logger.i("Cuenta confirmada ✅");
        navigatorKey.currentState?.pushReplacementNamed('/login');
      }

      if (uri.host == "reset-password") {
        logger.i("Redirigiendo a Reset Password 🔑");
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
          (route) => false,
        );
      }
    } catch (e) {
      logger.e("Error procesando el enlace: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/reset-password': (_) => const ResetPasswordPage(),
      },
      home: session == null ? const LoginPage() : const HomePage(),
    );
  }
}