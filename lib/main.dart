import 'package:flutter/material.dart';
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
import 'features/profile/presentation/providers/profile_provider.dart';

final logger = Logger();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(AnimalModelAdapter());

  await Supabase.initialize(
    url: 'https://ouxnrcamlloyhcanpbmb.supabase.co',
    anonKey: 'sb_publishable_a49vVecFsuol_HcWdCq_0Q_9SFGJTl1',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Cargar idioma por defecto antes de arrancar
  await AppStrings.load('es');

  runApp(
    const ProviderScope(
      child: AgrovetAI(),
    ),
  );
}

class AgrovetAI extends ConsumerStatefulWidget {
  const AgrovetAI({super.key});

  @override
  ConsumerState<AgrovetAI> createState() => _AgrovetAIState();
}

class _AgrovetAIState extends ConsumerState<AgrovetAI> {
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
        navigatorKey.currentState?.pushReplacementNamed('/login');
      }
      if (uri.host == "reset-password") {
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
    final themeMode = ref.watch(profileProvider).themeMode;
    final session = Supabase.instance.client.auth.currentSession;

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