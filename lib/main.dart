import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/lesson_plan_provider.dart';
import 'services/api_service.dart';
import 'services/local_storage_service.dart';
import 'services/theme_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/generate_screen.dart';
import 'screens/library_screen.dart';
import 'screens/plan_detail_screen.dart';
import 'screens/templates_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/ai_preferences_screen.dart';
import 'screens/help_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/about_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';
import 'widgets/page_transition.dart';
import 'services/whatsapp_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WhatsAppService.init();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAT5_uocnx8NM614LFkAEeUfBcJBuIeH1w',
        authDomain: 'smart-lesson-planner-922db.firebaseapp.com',
        projectId: 'smart-lesson-planner-922db',
        storageBucket: 'smart-lesson-planner-922db.firebasestorage.app',
        messagingSenderId: '544295063010',
        appId: '1:544295063010:web:ecfce7f6a8a1e829c9bdbb',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  final themeService = ThemeService();
  await themeService.load();
  runApp(SmartLessonPlannerApp(themeService: themeService));
}

class SmartLessonPlannerApp extends StatelessWidget {
  final ThemeService themeService;
  SmartLessonPlannerApp({super.key, required this.themeService});

  final _navigatorKey = GlobalKey<NavigatorState>();

  void _onSessionExpired() {
    LocalStorageService.clearAuthData();
    FirebaseAuth.instance.signOut();
    _navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Your session has expired. Please sign in again.')),
              ],
            ),
            backgroundColor: const Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService(onSessionExpired: _onSessionExpired);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProvider(create: (_) => LessonPlanProvider(apiService)),
      ],
      child: Consumer<ThemeService>(
        builder: (_, ts, __) => MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Smart Lesson Planner',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ts.themeMode,
          home: const SplashScreen(),
          routes: {
            '/login': (_) => const LoginScreen(),
            '/home': (_) => const AppShell(
              currentIndex: 0,
              pages: [
                HomeScreen(),
                GenerateScreen(),
                LibraryScreen(),
                ProfileScreen(),
              ],
            ),
            '/generate': (_) => const GenerateScreen(),
            '/library': (_) => const LibraryScreen(),
            '/templates': (_) => const TemplatesScreen(),
            '/profile': (_) => const ProfileScreen(),
            '/notifications': (_) => const NotificationsScreen(),
            '/ai-preferences': (_) => const AiPreferencesScreen(),
            '/help': (_) => const HelpScreen(),
            '/privacy': (_) => const PrivacyPolicyScreen(),
            '/about': (_) => const AboutScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/plan-detail') {
              final id = settings.arguments as int;
              return PageTransition.slideUp(PlanDetailScreen(planId: id));
            }
            if (settings.name == '/about') {
              return MaterialPageRoute(builder: (_) => const AboutScreen());
            }
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      const Text('Page not found'),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
