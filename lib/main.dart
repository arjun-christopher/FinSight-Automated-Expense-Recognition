import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/animated_splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Notification Service
  await NotificationService().initialize();
  
  runApp(const ProviderScope(child: FinSightApp()));
}

/// Provider to track if splash screen has been shown
final splashCompleteProvider = StateProvider<bool>((ref) => false);

class FinSightApp extends ConsumerWidget {
  const FinSightApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);
    final splashComplete = ref.watch(splashCompleteProvider);

    return MaterialApp(
      title: 'FinSight',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: splashComplete
          ? MaterialApp.router(
              title: 'FinSight',
              debugShowCheckedModeBanner: false,
              themeMode: themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              routerConfig: router,
            )
          : AnimatedSplashScreen(
              onComplete: () {
                ref.read(splashCompleteProvider.notifier).state = true;
              },
            ),
    );
  }
}
