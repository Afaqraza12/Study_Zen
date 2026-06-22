import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/user_provider.dart';
import '../../services/groq_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/glass_card.dart';
import '../health/health_screen.dart';
import '../subjects/subject_detail_screen.dart';
import '../settings/settings_screen.dart';
import '../gamification/progress_screen.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onSeeAllPressed;

  const HomeTab({super.key, required this.onSeeAllPressed});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  final GroqService _groqService = GroqService();
  String _dailyQuote = '';
  bool _isLoadingQuote = true;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _fetchDailyQuote();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _fetchDailyQuote() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final subjects = userProvider.user?.subjects ?? ['Computer Science'];
    
    final quote = await _groqService.getDailyMotivationalQuote(subjects);
    if (mounted) {
      setState(() {
        _dailyQuote = quote;
        _isLoadingQuote = false;
      });
    }
  }

  ImageProvider? _getAvatarProvider(String photoUrl) {
    if (photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('data:image')) {
      final base64Str = photoUrl.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    }
    return NetworkImage(photoUrl);
  }

  Gradient _getSubjectGradient(String subject) {
    final lower = subject.toLowerCase();
    if (lower.contains('c++')) return context.colors.cppGradient;
    if (lower.contains('dsa')) return context.colors.dsaGradient;
    if (lower.contains('coal')) return context.colors.coalGradient;
    if (lower.contains('os')) return context.colors.osGradient;
    if (lower.contains('web')) return context.colors.webGradient;
    return context.colors.primaryGradient;
  }

  IconData _getSubjectIcon(String subject) {
    final lower = subject.toLowerCase();
    if (lower.contains('c++')) return LucideIcons.terminal;
    if (lower.contains('dsa')) return LucideIcons.gitMerge;
    if (lower.contains('coal')) return LucideIcons.cpu;
    if (lower.contains('os')) return LucideIcons.layers;
    if (lower.contains('web')) return LucideIcons.globe;
    return LucideIcons.bookOpen;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    
    if (user == null) {
      return Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 120.0), // bottom padding for floating nav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: context.colors.primary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 20, // 40px diameter
                          backgroundColor: context.colors.surface,
                          backgroundImage: _getAvatarProvider(user.photoUrl),
                          child: user.photoUrl.isEmpty 
                              ? Icon(LucideIcons.user, color: context.colors.textSecondary)
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.split(' ').first,
                          style: context.textStyles.displayMedium.copyWith(fontSize: 24),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProgressScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.colors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Level ${user.level} • ${user.levelTitle}',
                              style: context.textStyles.bodySmall.copyWith(color: context.colors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(LucideIcons.bell, color: context.colors.textMain, size: 22),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.settings, color: context.colors.textMain, size: 22),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
            
            SizedBox(height: 32),

            // Stats Row (3 Glass Cards)
            Row(
              children: [
                Expanded(child: _buildStatCard(LucideIcons.flame, '${user.streak}', 'Streak', context.colors.accent)),
                SizedBox(width: 16),
                Expanded(child: _buildStatCard(LucideIcons.star, '${user.xp}', 'XP', context.colors.success)),
                SizedBox(width: 16),
                Expanded(child: _buildStatCard(LucideIcons.trophy, '${user.level}', 'Level', context.colors.warning)),
              ],
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

            SizedBox(height: 32),

            // Daily Motivation Card
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: const [Color(0xFF7C6EFA), Color(0xFF9B8BFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, _shimmerController.value + 0.5],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primary.withOpacity(0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -10,
                        left: -10,
                        child: Icon(
                          LucideIcons.quote,
                          size: 40,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          _isLoadingQuote
                              ? Center(child: CircularProgressIndicator(color: Colors.white))
                              : Text(
                                  _dailyQuote,
                                  style: context.textStyles.bodyLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ).animate().fadeIn(),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),

            SizedBox(height: 32),

            // Subjects Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Subjects', style: context.textStyles.titleLarge),
                TextButton(
                  onPressed: widget.onSeeAllPressed,
                  child: Text('See All', style: context.textStyles.bodyMedium.copyWith(color: context.colors.primary)),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms),
            
            SizedBox(height: 16),
            
            SizedBox(
              height: 220, // Increased height to prevent clipping
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: user.subjects.length,
                itemBuilder: (context, index) {
                  return _buildSubjectCard(user.subjects[index], index)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 300 + (index * 80)))
                      .slideX(begin: 0.1, end: 0);
                },
              ),
            ),

            SizedBox(height: 32),

            // Wellness Quick Card
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HealthScreen()),
                );
              },
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                borderColor: context.colors.success.withOpacity(0.3), // Green border accent
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.colors.success.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.timer, color: context.colors.success, size: 24),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Focus Mode', style: context.textStyles.titleLarge.copyWith(fontSize: 18)),
                        SizedBox(height: 4),
                        Text('Start a Pomodoro session', style: context.textStyles.bodyMedium),
                      ],
                    ),
                    const Spacer(),
                    Icon(LucideIcons.chevronRight, color: context.colors.textSecondary, size: 20),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: double.tryParse(value) ?? 0),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Text(
                val.toInt().toString(),
                style: context.textStyles.displaySmall,
              );
            },
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: context.textStyles.overline,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(String subject, int index) {
    final gradient = _getSubjectGradient(subject);
    final icon = _getSubjectIcon(subject);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectDetailScreen(
              subject: subject,
              color: gradient.colors.first,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: context.textStyles.displaySmall.copyWith(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.0, // 0% until Topic feature built
                      backgroundColor: Colors.white30,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '0% complete',
                    style: context.textStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
