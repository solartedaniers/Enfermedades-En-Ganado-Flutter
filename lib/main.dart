import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/notification_service.dart';
import 'core/services/offline_auth_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_strings.dart';
import 'features/animals/data/models/animal_model.dart';
import 'features/auth/home/screens/home_page.dart';
import 'features/auth/screens/login_page.dart';
import 'features/auth/screens/reset_password_page.dart';
import 'features/profile/presentation/providers/profile_provider.dart';

final logger = Logger();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError('Missing Supabase environment variables in .env');
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
  await OfflineAuthService.clearSession();
  await Supabase.instance.client.auth.signOut();

  runApp(const ProviderScope(child: AgrovetAI()));
}

class AgrovetAI extends ConsumerStatefulWidget {
  const AgrovetAI({super.key});

  @override
  ConsumerState<AgrovetAI> createState() => _AgrovetAIState();
}

class _AgrovetAIState extends ConsumerState<AgrovetAI>
    with WidgetsBindingObserver {
  final AppLinks _appLinks = AppLinks();
  final _supabase = Supabase.instance.client;
  bool _isClosingSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToAuthEvents();
    _initDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _closeSessionAndRedirect();
    }
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

  void _initDeepLinks() {
    _appLinks.uriLinkStream.listen((uri) async {
      logger.i('Received deep link: $uri');
      await _handleDeepLink(uri);
    });

    _appLinks.getInitialLink().then((uri) async {
      if (uri != null) {
        logger.i('Initial deep link: $uri');
        await _handleDeepLink(uri);
      }
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    try {
      await _supabase.auth.getSessionFromUrl(uri);

      if (uri.host == 'auth-confirm') {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (error) {
      logger.e('Error processing deep link: $error');
    }
  }

  Future<void> _closeSessionAndRedirect() async {
    if (_isClosingSession) {
      return;
    }

    _isClosingSession = true;
    await OfflineAuthService.clearSession();
    await _supabase.auth.signOut();
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    _isClosingSession = false;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(profileProvider).themeMode;

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
      home: const LoginPage(),
    );
  }
}
