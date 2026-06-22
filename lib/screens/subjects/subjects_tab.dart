import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../subjects/subject_detail_screen.dart';
import '../auth/subject_selection_screen.dart';

class SubjectsTab extends StatelessWidget {
  const SubjectsTab({super.key});

  Gradient _getSubjectGradient(BuildContext context, String subject) {
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

    return Scaffold(
      backgroundColor: Colors.transparent, // Important: let HomeScreen background show
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 0), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Subjects', style: context.textStyles.displayMedium).animate().fadeIn().slideY(begin: -0.1, end: 0),
              SizedBox(height: 4),
              Text(
                '${user.subjects.length} subjects enrolled',
                style: context.textStyles.bodyMedium,
              ).animate().fadeIn(delay: 100.ms),
              SizedBox(height: 32),
              
              Expanded(
                child: user.subjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.bookX, size: 64, color: context.colors.textSecondary),
                            SizedBox(height: 16),
                            Text('No subjects yet.', style: context.textStyles.titleLarge),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 120.0), // Padding for floating nav!
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8, 
                        ),
                        itemCount: user.subjects.length,
                        itemBuilder: (context, index) {
                          final subject = user.subjects[index];
                          final gradient = _getSubjectGradient(context, subject);
                          final icon = _getSubjectIcon(subject);
                          
                          return _buildSubjectGridCard(context, subject, gradient, icon)
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: 200 + (index * 80)))
                              .scale(begin: const Offset(0.95, 0.95));
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Above the floating nav
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SubjectSelectionScreen(isEditing: true)),
            );
          },
          backgroundColor: context.colors.primary,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: context.colors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: context.colors.primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(LucideIcons.plus, color: Colors.white, size: 28),
          ),
        ).animate().fadeIn(delay: 500.ms).scale(curve: Curves.easeOutBack),
      ),
    );
  }

  Widget _buildSubjectGridCard(BuildContext context, String subject, Gradient gradient, IconData icon) {
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.2), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  SizedBox(height: 12),
                  Text(
                    subject,
                    style: context.textStyles.titleLarge.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.0, 
                      backgroundColor: Colors.white30,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '0% complete',
                    style: context.textStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
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
