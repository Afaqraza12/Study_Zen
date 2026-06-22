import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/glass_card.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    
    if (user == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final int xpForNextLevel = user.nextLevelBaseXP;
    final double progress = user.levelProgress;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: context.colors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Your Journey', style: context.textStyles.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card: Level & XP Ring
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E2A54), context.colors.surface],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: context.colors.primary.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.primary.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return CircularProgressIndicator(
                              value: value,
                              backgroundColor: context.colors.surface2,
                              valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                              strokeWidth: 12,
                              strokeCap: StrokeCap.round,
                            );
                          },
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Lvl',
                                style: context.textStyles.overline.copyWith(color: context.colors.primary),
                              ),
                              Text(
                                '${user.level}',
                                style: context.textStyles.displayLarge.copyWith(fontSize: 40),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                  SizedBox(height: 24),
                  Text(
                    'Level ${user.level} ${user.levelTitle}',
                    style: context.textStyles.displaySmall,
                  ).animate().fadeIn(delay: 300.ms),
                  SizedBox(height: 8),
                  Text(
                    user.level >= 8 
                        ? 'Max Level Reached!' 
                        : '${xpForNextLevel - user.xp} XP to next level',
                    style: context.textStyles.bodyMedium,
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

            SizedBox(height: 48),

            // Badges Section
            Text('Earned Badges', style: context.textStyles.titleLarge).animate().fadeIn(delay: 500.ms),
            SizedBox(height: 16),
            
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildAchievementBadge(context, LucideIcons.flame, '3-Day Streak', context.colors.accent, user.streak >= 3),
                _buildAchievementBadge(context, LucideIcons.star, 'First 100 XP', context.colors.success, user.xp >= 100),
                _buildAchievementBadge(context, LucideIcons.terminal, 'First Compile', context.colors.primary, true),
                _buildAchievementBadge(context, LucideIcons.bot, 'AI Chat', const Color(0xFF38BDF8), true),
                _buildAchievementBadge(context, LucideIcons.flame, '7-Day Streak', context.colors.accent, user.streak >= 7),
                _buildAchievementBadge(context, LucideIcons.trophy, 'Level 5', context.colors.warning, user.level >= 5),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(BuildContext context, IconData icon, String title, Color color, bool isUnlocked) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked ? color.withOpacity(0.15) : context.colors.surface,
            border: Border.all(
              color: isUnlocked ? color.withOpacity(0.5) : context.colors.border,
              width: 2,
            ),
            boxShadow: isUnlocked ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Icon(
            isUnlocked ? icon : LucideIcons.lock,
            color: isUnlocked ? color : context.colors.textSecondary.withOpacity(0.5),
            size: 32,
          ),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: context.textStyles.bodySmall.copyWith(
            color: isUnlocked ? context.colors.textMain : context.colors.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.8, 0.8));
  }
}
