import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:logger/logger.dart';

import 'features/auth/screens/login_page.dart';
import 'features/auth/home/screens/home_page.dart';
import 'features/auth/screens/reset_password_page.dart'; // 👈 nueva pantalla

final logger = Logger();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      logger.i("DeepLink recibido: $uri");

      if (uri.host == "auth-confirm") {
        logger.i("Cuenta confirmada ✅");
      }

      if (uri.host == "reset-password") {
        logger.i("Reset password solicitado 🔑");

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const ResetPasswordPage(),
          ),
        );
      }
    });

    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        logger.i("DeepLink inicial: $uri");

        if (uri.host == "auth-confirm") {
          logger.i("Cuenta confirmada desde enlace inicial ✅");
        }

        if (uri.host == "reset-password") {
          logger.i("Reset password solicitado desde enlace inicial 🔑");

          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => const ResetPasswordPage(),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      navigatorKey: navigatorKey, // 👈 agregado
      debugShowCheckedModeBanner: false,
      home: SplashScreen(
        nextPage: session == null ? const LoginPage() : const HomePage(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final Widget nextPage;
  const SplashScreen({super.key, required this.nextPage});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => widget.nextPage),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ClipOval(
          child: Image.asset(
            'lib/images/logo.webp',
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}