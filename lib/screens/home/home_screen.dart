import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../providers/user_provider.dart';
import 'home_tab.dart';
import '../subjects/subjects_tab.dart';
import '../ai_tutor/ai_tutor_selector_screen.dart';
import '../gamification/progress_screen.dart';
import '../social/leaderboard_screen.dart';
import '../settings/settings_screen.dart';
import '../compiler/compiler_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<Widget> get _tabs => [
    HomeTab(
      onSeeAllPressed: () {
        setState(() {
          _currentIndex = 1;
        });
      },
    ),
    const SubjectsTab(),
    const AITutorSelectorScreen(),
    const CompilerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      extendBody: true,
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        title: Text(
          'StudyZen',
          style: TextStyle(
            color: context.colors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (user != null) ...[
            // Global XP Badge
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProgressScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: context.colors.surface2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.star, color: context.colors.primary, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Lvl ${user.level} • ${user.xp} XP',
                      style: TextStyle(
                        color: context.colors.textMain,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8),
            // Global Streak Badge
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: context.colors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.flame, color: context.colors.accent, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '${user.streak}',
                    style: TextStyle(
                      color: context.colors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            // Leaderboard Button
            IconButton(
              icon: Icon(LucideIcons.trophy, color: Color(0xFFFFD700)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                );
              },
            ),
            // Settings Button
            IconButton(
              icon: Icon(LucideIcons.settings, color: context.colors.textSecondary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            SizedBox(width: 8),
          ],
        ],
      ),
      body: Stack(
        children: [
          _tabs[_currentIndex],
          
          // Floating Bottom Navigation
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xE612121A), // 90% opacity surface
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(child: _buildNavItem(0, LucideIcons.home, 'Home')),
                      Flexible(child: _buildNavItem(1, LucideIcons.bookOpen, 'Subjects')),
                      Flexible(child: _buildNavItem(2, LucideIcons.bot, 'Tutor')),
                      Flexible(child: _buildNavItem(3, LucideIcons.terminal, 'Compiler')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primaryGlow : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                color: isSelected ? context.colors.primary : context.colors.textSecondary.withOpacity(0.6),
                size: 22,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
