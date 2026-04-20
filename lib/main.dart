import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_route_paths.dart';
import 'core/network/network_provider.dart';
import 'core/services/app_sync_service.dart';
import 'core/services/local_preferences_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_strings.dart';
import 'features/animals/data/models/animal_model.dart';
import 'features/animals/presentation/providers/animal_provider.dart';
import 'features/auth/home/screens/home_page.dart';
import 'features/auth/screens/login_page.dart';
import 'features/auth/screens/reset_password_page.dart';
import 'features/auth/services/auth_service.dart';
import 'features/profile/presentation/providers/managed_client_provider.dart';
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
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(AnimalModelAdapter());
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  final currentUser = Supabase.instance.client.auth.currentUser;
  final localPreferences = await LocalPreferencesService.load(
    scope: LocalPreferencesService.scopeFromIdentity(
      email: currentUser?.email,
      userId: currentUser?.id,
    ),
  );
  await AppStrings.load(localPreferences.language);
  await NotificationService.init();

  runApp(
    ProviderScope(
      overrides: [
        profilePreferencesProvider.overrideWithValue(localPreferences),
      ],
      child: const AgrovetAI(),
    ),
  );
}

class AgrovetAI extends ConsumerStatefulWidget {
  const AgrovetAI({super.key});

  @override
  ConsumerState<AgrovetAI> createState() => _AgrovetAIState();
}

class _AgrovetAIState extends ConsumerState<AgrovetAI> {
  AppSyncService? _appSyncService;
  final AppLinks _appLinks = AppLinks();
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _listenToAuthEvents();
    _listenToDeepLinks();
    _appSyncService = AppSyncService(
      animalRepository: ref.read(animalRepositoryProvider),
      networkInfo: ref.read(networkInfoProvider),
      managedClientService: ref.read(managedClientServiceProvider),
      authService: AuthService(),
      supabaseClient: Supabase.instance.client,
    );
    _appSyncService?.start();
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

  void _listenToDeepLinks() {
    _appLinks.uriLinkStream.listen((uri) => _handleDeepLink(uri));
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
    } catch (e) {
      logger.e('Error handling deep link', error: e);
    }
  }

  @override
  void dispose() {
    _appSyncService?.stop();
    super.dispose();
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
        AppRoutePaths.login: (_) => const LoginPage(),
        AppRoutePaths.home: (_) => const HomePage(),
        AppRoutePaths.resetPassword: (_) => const ResetPasswordPage(),
      },
      home: session == null ? const LoginPage() : const HomePage(),
    );
  }
}
