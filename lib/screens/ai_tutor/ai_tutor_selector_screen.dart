import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/chat_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import 'ai_tutor_screen.dart';

class AITutorSelectorScreen extends StatefulWidget {
  const AITutorSelectorScreen({super.key});

  @override
  State<AITutorSelectorScreen> createState() => _AITutorSelectorScreenState();
}

class _AITutorSelectorScreenState extends State<AITutorSelectorScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedSubject = '';

  Gradient _getSubjectGradient(String subject) {
    final lower = subject.toLowerCase();
    if (lower.contains('c++')) return context.colors.cppGradient;
    if (lower.contains('dsa')) return context.colors.dsaGradient;
    if (lower.contains('coal')) return context.colors.coalGradient;
    if (lower.contains('os')) return context.colors.osGradient;
    if (lower.contains('web')) return context.colors.webGradient;
    return context.colors.primaryGradient;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_selectedSubject.isEmpty && user.subjects.isNotEmpty) {
      _selectedSubject = user.subjects.first;
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 120.0), // Padding for floating nav
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Tutor Hub', style: context.textStyles.displayMedium).animate().fadeIn().slideY(begin: -0.1, end: 0),
              SizedBox(height: 4),
              Text(
                'Resume a session or start a new one.',
                style: context.textStyles.bodyMedium,
              ).animate().fadeIn(delay: 100.ms),
              SizedBox(height: 32),
              
              Text('Recent Sessions', style: context.textStyles.titleLarge).animate().fadeIn(delay: 200.ms),
              SizedBox(height: 16),
              
              Expanded(
                child: StreamBuilder<List<ChatSession>>(
                  stream: _firestoreService.getUserChatSessions(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final sessions = snapshot.data ?? [];

                    if (sessions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.messageSquareDashed, size: 64, color: context.colors.textSecondary),
                            SizedBox(height: 16),
                            Text('No chat history found.', style: context.textStyles.titleLarge),
                          ],
                        ),
                      ).animate().fadeIn();
                    }

                    return ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final gradient = _getSubjectGradient(session.subject);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AITutorScreen(
                                    selectedSubject: session.subject,
                                    existingSessionId: session.id,
                                    themeColor: gradient.colors.first,
                                  ),
                                ),
                              );
                            },
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: gradient,
                                    ),
                                    child: Icon(LucideIcons.bot, color: Colors.white),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          session.title,
                                          style: context.textStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          session.subject,
                                          style: context.textStyles.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(LucideIcons.chevronRight, color: context.colors.textSecondary),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1, end: 0),
                        );
                      },
                    );
                  },
                ),
              ),
              
              SizedBox(height: 16),
              
              // Start New Chat Section
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start New Chat', style: context.textStyles.titleLarge),
                    SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.colors.surface2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSubject,
                          isExpanded: true,
                          dropdownColor: context.colors.surface2,
                          icon: Icon(LucideIcons.chevronDown, color: context.colors.textSecondary),
                          style: context.textStyles.bodyLarge,
                          items: user.subjects.map((String subject) {
                            return DropdownMenuItem<String>(
                              value: subject,
                              child: Text(subject),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedSubject = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    GradientButton(
                      text: 'Begin Session',
                      icon: LucideIcons.messagesSquare,
                      onPressed: () {
                        if (_selectedSubject.isEmpty) return;
                        final gradient = _getSubjectGradient(_selectedSubject);
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AITutorScreen(
                              selectedSubject: _selectedSubject,
                              themeColor: gradient.colors.first,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
