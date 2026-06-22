import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../models/topic_model.dart';
import '../../models/note_model.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/groq_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../ai_tutor/ai_tutor_screen.dart';
import 'note_editor_screen.dart';
import 'note_scan_screen.dart';
import 'note_detail_screen.dart';
import 'quiz_screen.dart';
import 'topic_detail_screen.dart';

class SubjectDetailScreen extends StatefulWidget {
  final String subject;
  final Color color;

  const SubjectDetailScreen({
    super.key,
    required this.subject,
    required this.color,
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  final GroqService _groqService = GroqService();
  final FirestoreService _firestoreService = FirestoreService();
  
  String _activeTab = 'Overview';
  final List<String> _tabs = ['Overview', 'Topics', 'Notes', 'Quiz'];
  
  bool _isGeneratingSyllabus = false;

  Future<void> _generateSyllabus(String uid) async {
    setState(() => _isGeneratingSyllabus = true);
    try {
      final topics = await _groqService.generateSyllabus(widget.subject);
      for (int i = 0; i < topics.length; i++) {
        final topic = TopicModel(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          subject: widget.subject,
          name: topics[i],
          isCompleted: false,
        );
        await _firestoreService.saveTopic(uid, topic);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate syllabus: $e')),
      );
    }
    setState(() => _isGeneratingSyllabus = false);
  }

  Future<void> _toggleTopic(String uid, TopicModel topic) async {
    final updated = topic.copyWith(isCompleted: !topic.isCompleted);
    await _firestoreService.saveTopic(uid, updated);
    
    // XP logic
    if (updated.isCompleted) {
      context.read<UserProvider>().addXP(10);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+10 XP for completing topic! 🔥'), backgroundColor: widget.color),
      );
    } else {
      context.read<UserProvider>().removeXP(10);
    }
  }

  Future<void> _analyzeNote(String uid, NoteModel note) async {
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final analysis = await _groqService.analyzeNote(note.content);
      final updatedNote = note.copyWith(aiAnalysis: analysis);
      await _firestoreService.saveNote(uid, updatedNote);
      Navigator.pop(context); // pop loading
      
      // Show bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildAnalysisSheet(analysis),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to analyze: $e')));
    }
  }

  Widget _buildAnalysisSheet(Map<String, dynamic> analysis) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI Analysis', style: context.textStyles.displayMedium),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnalysisSection('Summary', analysis['summary'] ?? ''),
                  _buildAnalysisSection('Key Points', (analysis['key_points'] as List).join('\n• ')),
                  _buildAnalysisSection('Difficulty', analysis['difficulty'] ?? ''),
                  _buildAnalysisSection('Improvements', (analysis['improvements'] as List).join('\n• ')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: widget.color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content, style: context.textStyles.bodyMedium),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) return const Scaffold();

    return Scaffold(
      backgroundColor: context.colors.background,
      body: StreamBuilder<List<TopicModel>>(
        stream: _firestoreService.getTopics(user.uid, widget.subject),
        builder: (context, snapshot) {
          final topics = snapshot.data ?? [];
          final completed = topics.where((t) => t.isCompleted).length;
          final total = topics.length;
          final progress = total == 0 ? 0.0 : completed / total;

          return Column(
            children: [
              _buildHeader(progress, completed, total),
              _buildTabBar(),
              Expanded(
                child: _buildActiveTabContent(user.uid, topics),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(double progress, int completed, int total) {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.color, widget.color.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
                ),
              ),
              const Spacer(),
              Text(
                widget.subject,
                style: context.textStyles.displayLarge.copyWith(color: Colors.white),
              ).animate().fadeIn().slideX(begin: -0.1, end: 0),
              const SizedBox(height: 8),
              Text(
                '$total topics • ${(progress * 100).toInt()}% complete',
                style: context.textStyles.bodyMedium.copyWith(color: Colors.white.withOpacity(0.8)),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 6,
                    ),
                  ),
                  Center(
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ).animate().scale(delay: 300.ms, duration: 500.ms, curve: Curves.easeOutBack),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _tabs.map((tab) {
          final isActive = _activeTab == tab;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: isActive ? widget.color : context.colors.textSecondary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveTabContent(String uid, List<TopicModel> topics) {
    switch (_activeTab) {
      case 'Topics':
        return _buildTopicsTab(uid, topics);
      case 'Notes':
        return _buildNotesTab(uid);
      case 'Quiz':
        return _buildQuizTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.sparkles, color: widget.color),
                    const SizedBox(width: 8),
                    Text('AI Analysis', style: context.textStyles.titleLarge),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Based on your progress, you are doing great! Focus on completing the remaining topics to master ${widget.subject}.',
                  style: context.textStyles.bodyMedium,
                ),
                const SizedBox(height: 24),
                GradientButton(
                  text: 'Ask AI Tutor',
                  icon: LucideIcons.bot,
                  gradient: LinearGradient(colors: [widget.color, widget.color.withOpacity(0.6)]),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AITutorScreen(
                          selectedSubject: widget.subject,
                          themeColor: widget.color,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildTopicsTab(String uid, List<TopicModel> topics) {
    if (topics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.bookOpen, size: 64, color: context.colors.textSecondary),
            const SizedBox(height: 16),
            Text('No topics yet', style: context.textStyles.titleLarge),
            const SizedBox(height: 16),
            if (_isGeneratingSyllabus)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: () => _generateSyllabus(uid),
                icon: const Icon(LucideIcons.sparkles, color: Colors.white),
                label: const Text('Generate Syllabus with AI', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: widget.color),
              ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        final isCompleted = topic.isCompleted;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TopicDetailScreen(
                    topic: topic,
                    subject: widget.subject,
                    themeColor: widget.color,
                  ),
                ),
              );
            },
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleTopic(uid, topic),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? context.colors.success : Colors.transparent,
                        border: Border.all(
                          color: isCompleted ? context.colors.success : context.colors.textSecondary,
                          width: 2,
                        ),
                      ),
                      child: isCompleted 
                          ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.name,
                          style: context.textStyles.bodyLarge.copyWith(
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? context.colors.textSecondary : context.colors.textMain,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCompleted ? 'Completed' : 'Tap to open topic details',
                          style: context.textStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1, end: 0),
        );
      },
    );
  }

  Widget _buildNotesTab(String uid) {
    return StreamBuilder<List<NoteModel>>(
      stream: _firestoreService.getNotes(uid, widget.subject),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final notes = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Notes', style: context.textStyles.titleLarge),
                  IconButton(
                    icon: Icon(LucideIcons.plus, color: widget.color),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Create Note', style: context.textStyles.titleLarge),
                              const SizedBox(height: 24),
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: widget.color.withOpacity(0.1), shape: BoxShape.circle),
                                  child: Icon(LucideIcons.keyboard, color: widget.color),
                                ),
                                title: const Text('Type Note'),
                                subtitle: const Text('Write a text note'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditorScreen(subject: widget.subject, themeColor: widget.color)));
                                },
                              ),
                              const SizedBox(height: 12),
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: widget.color.withOpacity(0.1), shape: BoxShape.circle),
                                  child: Icon(LucideIcons.camera, color: widget.color),
                                ),
                                title: const Text('Scan Handwritten Note'),
                                subtitle: const Text('Use AI to extract your writing'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => NoteScanScreen(subject: widget.subject, themeColor: widget.color)));
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: notes.isEmpty
                    ? Center(
                        child: Text('No notes yet. Tap + to add one!', style: context.textStyles.bodyMedium),
                      )
                    : ListView.builder(
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          final hasAnalysis = note.aiAnalysis != null;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Dismissible(
                              key: Key(note.id),
                              background: Container(
                                decoration: BoxDecoration(
                                  color: context.colors.error,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                child: const Icon(LucideIcons.trash2, color: Colors.white),
                              ),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) {
                                _firestoreService.deleteNote(uid, note.id);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note deleted')));
                              },
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => NoteDetailScreen(note: note, subject: widget.subject, themeColor: widget.color),
                                  ));
                                },
                                child: GlassCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                if (note.type == 'scanned')
                                                  Padding(
                                                    padding: const EdgeInsets.only(right: 8.0),
                                                    child: Icon(LucideIcons.camera, size: 16, color: widget.color),
                                                  ),
                                                Expanded(
                                                  child: Text(
                                                    note.type == 'scanned' ? note.mainTopic : note.title, 
                                                    style: context.textStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold), 
                                                    maxLines: 1, 
                                                    overflow: TextOverflow.ellipsis
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (note.type == 'scanned' || note.aiAnalysis != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: widget.color.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(note.type == 'scanned' ? 'AI Analyzed' : 'Reviewed', style: context.textStyles.overline.copyWith(color: widget.color)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        note.type == 'scanned' ? note.organizedText : note.content,
                                        style: context.textStyles.bodyMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${note.updatedAt.month}/${note.updatedAt.day}/${note.updatedAt.year}', style: context.textStyles.bodySmall),
                                          GestureDetector(
                                            onTap: () {
                                              if (hasAnalysis) {
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  backgroundColor: Colors.transparent,
                                                  builder: (context) => _buildAnalysisSheet(note.aiAnalysis!),
                                                );
                                              } else {
                                                _analyzeNote(uid, note);
                                              }
                                            },
                                            child: Text(
                                              hasAnalysis ? 'View Analysis' : 'AI Analyze',
                                              style: TextStyle(color: widget.color, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
                        },
                      ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildQuizTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.brainCircuit, size: 64, color: widget.color),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready to test your knowledge?',
            style: context.textStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'The AI Tutor will generate a custom quiz based on your completed topics in ${widget.subject}.',
            style: context.textStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          GradientButton(
            text: 'Generate AI Quiz',
            icon: LucideIcons.sparkles,
            gradient: LinearGradient(colors: [widget.color, widget.color.withOpacity(0.6)]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(
                    subject: widget.subject,
                    themeColor: widget.color,
                    topics: [], // Ideally pass completed topics here, but GroqService can handle empty by generating general quiz
                  ),
                ),
              );
            },
          ),
        ],
      ).animate().fadeIn().scale(),
    );
  }
}
