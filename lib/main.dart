import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:logger/logger.dart';

// Importaciones de tus pantallas y temas
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_page.dart';
import 'features/auth/home/screens/home_page.dart';
import 'features/auth/screens/reset_password_page.dart';

final logger = Logger();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Supabase con tu URL y Key
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

  // Manejo de enlaces externos (Confirmación de cuenta / Reset Password)
  void initDeepLinks() {
    _appLinks.uriLinkStream.listen((uri) {
      if (uri.host == "reset-password") {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'AgroVet AI',
      // Aplicación del nuevo tema profesional
      theme: AppTheme.lightTheme, 
      home: SplashScreen(
        nextPage: session == null ? const LoginPage() : const HomePage(),
      ),
    );
  }
}

// Pantalla de carga inicial (Branding)
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
    // Delay de 3 segundos para mostrar el logo
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
      backgroundColor: Colors.white,
      body: Center(
        child: Hero(
          tag: 'logo',
          child: ClipOval(
            child: Image.asset(
              'lib/images/logo.webp',
              width: 180,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}