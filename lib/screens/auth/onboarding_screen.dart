import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import 'subject_selection_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Learn Smarter',
      'description': 'Your AI-powered tutor helps you understand complex topics with ease.',
      'icon': 'school', // Icon name placeholder
    },
    {
      'title': 'Track Progress',
      'description': 'Keep up with your study streak and monitor your performance over time.',
      'icon': 'trending_up',
    },
    {
      'title': 'Beat Your Friends',
      'description': 'Earn XP, level up, and climb the leaderboard. Studying is now a game!',
      'icon': 'emoji_events',
    },
  ];

  IconData _getIconData(String name) {
    switch (name) {
      case 'school':
        return Icons.school_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userCred = await authService.signInWithGoogle();
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (userCred != null) {
      // For simplicity, checking if new user. If so, go to SubjectSelection
      // Real app might check Firestore directly if subjects array is empty.
      // Let's route to Subject Selection for now to ensure they pick subjects.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SubjectSelectionScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIconData(slide['icon']!),
                          size: 120,
                          color: context.colors.primary,
                        ).animate().scale(duration: 400.ms, delay: 200.ms),
                        SizedBox(height: 48),
                        Text(
                          slide['title']!,
                          style: Theme.of(context).textTheme.displayMedium,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                        SizedBox(height: 16),
                        Text(
                          slide['description']!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: context.colors.textSecondary,
                                height: 1.5,
                              ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? context.colors.primary : context.colors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            SizedBox(height: 48),
            // Bottom Action Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: _currentPage == _slides.length - 1
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        icon: _isLoading 
                          ? SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Icon(Icons.login),
                        label: Text('Continue with Google'),
                      ).animate().fadeIn().scale(),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => _pageController.animateToPage(
                            _slides.length - 1,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          ),
                          child: Text('Skip'),
                        ),
                        ElevatedButton(
                          onPressed: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(16),
                          ),
                          child: Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
