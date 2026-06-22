import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const StudyZenApp());
}

class StudyZenApp extends StatelessWidget {
  const StudyZenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<PomodoroProvider>(create: (_) => PomodoroProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'StudyZen',
            theme: ThemeData.dark(), 
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: KeyedSubtree(
                  key: ValueKey(themeProvider.currentTheme),
                  child: child!,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
