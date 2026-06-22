import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../providers/user_provider.dart';
import 'onboarding_screen.dart';
import '../home/home_screen.dart';
import 'subject_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchUser(authService.currentUser!.uid);
      
      if (!mounted) return;
      
      if (userProvider.user != null && userProvider.user!.subjects.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SubjectSelectionScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Books + Brain Icon using Flutter Icons for now
            Icon(
              Icons.menu_book_rounded,
              size: 80,
              color: context.colors.primary,
            ).animate().scale(duration: 500.ms).then().shake(duration: 500.ms),
            SizedBox(height: 24),
            Text(
              'StudyZen',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: context.colors.primary,
                  ),
            ).animate().fadeIn(delay: 500.ms, duration: 500.ms).slideY(begin: 0.5, end: 0),
            SizedBox(height: 8),
            Text(
              'Learn Smarter, Not Harder',
              style: Theme.of(context).textTheme.bodyMedium,
            ).animate().fadeIn(delay: 1000.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
