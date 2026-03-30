import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:logger/logger.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/animals/data/models/animal_model.dart';
import 'features/auth/screens/login_page.dart';
import 'features/auth/home/screens/home_page.dart';
import 'features/auth/screens/reset_password_page.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_strings.dart';
import 'core/services/notification_service.dart';
import 'features/profile/presentation/providers/profile_provider.dart';

final logger = Logger();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing Supabase environment variables in .env',
    );
  }

  await Hive.initFlutter();
  Hive.registerAdapter(AnimalModelAdapter());

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  await AppStrings.load('es');
  await NotificationService.init();

  runApp(const ProviderScope(child: AgrovetAI()));
}

class AgrovetAI extends ConsumerStatefulWidget {
  const AgrovetAI({super.key});

  @override
  ConsumerState<AgrovetAI> createState() => _AgrovetAIState();
}

class _AgrovetAIState extends ConsumerState<AgrovetAI> {
  final AppLinks _appLinks = AppLinks();
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _listenToAuthEvents();
    initDeepLinks();
  }

  // Escucha eventos de auth — esto atrapa el passwordRecovery
  void _listenToAuthEvents() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      if (event == AuthChangeEvent.passwordRecovery) {
        // Supabase estableció sesión temporal para reset
        // Navega a ResetPasswordPage sin importar dónde esté el usuario
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const ResetPasswordPage(),
          ),
          (route) => false,
        );
      }
    });
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
      // Esto procesa el token del enlace y dispara onAuthStateChange
      // con el evento correcto (passwordRecovery o signedIn)
      await _supabase.auth.getSessionFromUrl(uri);

      if (uri.host == "auth-confirm") {
        logger.i("Cuenta confirmada ✅");
        // Solo redirige al login, no al home
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }

      // El caso reset-password ya lo maneja _listenToAuthEvents
      // con el evento passwordRecovery, no hace falta manejarlo aquí

    } catch (e) {
      logger.e("Error procesando el enlace: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(profileProvider).themeMode;
    final session = _supabase.auth.currentSession;

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/reset-password': (_) => const ResetPasswordPage(),
      },
      home: session == null ? const LoginPage() : const HomePage(),
    );
  }
}
