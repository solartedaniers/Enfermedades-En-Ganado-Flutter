import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:logger/logger.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  // Carga de variables de entorno (Groq API Key)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    logger.w('No se pudo cargar el archivo .env', error: e);
  }

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(AnimalModelAdapter());
  }

  await Supabase.initialize(
    url: 'https://ouxnrcamlloyhcanpbmb.supabase.co',
    anonKey: 'sb_publishable_a49vVecFsuol_HcWdCq_0Q_9SFGJTl1',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  await AppStrings.load('es');
  await NotificationService.init();

  runApp(const ProviderScope(child: AgrovetAI()));
}

// ESTA ES LA CLASE QUE DART NO ENCONTRABA:
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

  void _listenToAuthEvents() {
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
          (route) => false,
        );
      }
    });
  }

  void initDeepLinks() {
    _appLinks.uriLinkStream.listen((uri) => _handleDeepLink(uri));
  }

  Future<void> _handleDeepLink(Uri uri) async {
    try {
      await _supabase.auth.getSessionFromUrl(uri);
      if (uri.host == "auth-confirm") {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      logger.e("Error DeepLink: $e");
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
