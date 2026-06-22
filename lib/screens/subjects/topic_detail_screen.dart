import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../models/topic_model.dart';
import '../../models/topic_content_model.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/groq_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/glass_card.dart';

class TopicDetailScreen extends StatefulWidget {
  final TopicModel topic;
  final String subject;
  final Color themeColor;

  const TopicDetailScreen({
    super.key,
    required this.topic,
    required this.subject,
    required this.themeColor,
  });

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  final GroqService _groqService = GroqService();
  final FirestoreService _firestoreService = FirestoreService();
  
  TopicContentModel? _content;
  bool _isLoading = true;
  bool _isCompleted = false;
  
  final Map<int, String> _aiAnswers = {};
  final Map<int, bool> _isLoadingAnswer = {};

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.topic.isCompleted;
    _loadContent();
  }

  Future<void> _loadContent() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    // 1. Try to load from Firestore
    final cached = await _firestoreService.getTopicContent(user.uid, widget.topic.id);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _content = cached;
          _isLoading = false;
        });
      }
      return;
    }

    // 2. Fetch from Groq if not cached
    final generatedJson = await _groqService.generateTopicContent(widget.subject, widget.topic.name);
    
    if (generatedJson != null) {
      final newContent = TopicContentModel.fromMap(generatedJson);
      if (mounted) {
        setState(() {
          _content = newContent;
          _isLoading = false;
        });
      }
      // Save to Firestore for future
      await _firestoreService.saveTopicContent(user.uid, widget.topic.id, newContent);
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate topic content.')),
        );
      }
    }
  }

  Future<void> _toggleComplete() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final newState = !_isCompleted;
    
    setState(() => _isCompleted = newState);

    final updatedTopic = widget.topic.copyWith(isCompleted: newState);
    await _firestoreService.saveTopic(user.uid, updatedTopic);

    if (newState) {
      context.read<UserProvider>().addXP(10);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('+10 XP for completing topic! 🔥'), backgroundColor: widget.themeColor),
      );
    } else {
      context.read<UserProvider>().removeXP(10);
    }
  }

  Future<void> _getAIAnswer(int questionIndex, String question) async {
    setState(() => _isLoadingAnswer[questionIndex] = true);
    final answer = await _groqService.sendMessage(widget.subject, 'Answer this practice question: $question');
    if (mounted) {
      setState(() {
        _aiAnswers[questionIndex] = answer;
        _isLoadingAnswer[questionIndex] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_content != null)
                SliverPadding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildOverview(),
                      const SizedBox(height: 24),
                      _buildKeyConcepts(),
                      const SizedBox(height: 24),
                      _buildExplanation(),
                      const SizedBox(height: 24),
                      if (_content!.codeExample.isNotEmpty && _content!.codeExample.toLowerCase() != 'none')
                        _buildCodeExample(),
                      const SizedBox(height: 24),
                      _buildCommonMistakes(),
                      const SizedBox(height: 24),
                      _buildPracticeQuestions(),
                      const SizedBox(height: 24),
                      _buildProTip(),
                    ]),
                  ),
                )
              else
                SliverFillRemaining(
                  child: Center(
                    child: Text('Content unavailable.', style: context.textStyles.bodyLarge),
                  ),
                ),
            ],
          ),
          
          // Bottom Complete Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.background.withOpacity(0.0),
                    context.colors.background,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: ElevatedButton(
                onPressed: _toggleComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCompleted ? context.colors.surface : widget.themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: _isCompleted ? BorderSide(color: widget.themeColor) : BorderSide.none,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isCompleted ? LucideIcons.checkCircle2 : LucideIcons.circle,
                      color: _isCompleted ? widget.themeColor : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isCompleted ? '✓ Completed' : 'Mark as Complete (+10 XP)',
                      style: TextStyle(
                        color: _isCompleted ? widget.themeColor : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, end: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: widget.themeColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        title: Text(
          widget.topic.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.themeColor, widget.themeColor.withOpacity(0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.themeColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.bookOpen, color: widget.themeColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _content!.overview,
              style: context.textStyles.bodyMedium.copyWith(color: context.colors.textMain, height: 1.5),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildKeyConcepts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Key Concepts', style: context.textStyles.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _content!.keyConcepts.map((concept) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.colors.border),
              ),
              child: Text(concept, style: context.textStyles.bodySmall.copyWith(color: context.colors.textMain)),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildExplanation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Detailed Explanation', style: context.textStyles.titleLarge),
        const SizedBox(height: 12),
        Text(
          _content!.explanation,
          style: TextStyle(
            color: context.colors.textMain,
            fontFamily: 'Inter',
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildCodeExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Code Example', style: context.textStyles.titleLarge),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: context.colors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Code', style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _content!.codeExample));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
                      },
                      child: Icon(LucideIcons.copy, color: context.colors.textSecondary, size: 16),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _content!.codeExample,
                  style: context.textStyles.code.copyWith(color: widget.themeColor, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildCommonMistakes() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertCircle, color: context.colors.error),
              const SizedBox(width: 8),
              Text('Common Mistakes', style: context.textStyles.titleLarge.copyWith(color: context.colors.error)),
            ],
          ),
          const SizedBox(height: 16),
          ..._content!.commonMistakes.map((mistake) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.x, color: context.colors.error, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(mistake, style: context.textStyles.bodyMedium),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildPracticeQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Practice Questions', style: context.textStyles.titleLarge),
        const SizedBox(height: 12),
        ..._content!.practiceQuestions.asMap().entries.map((entry) {
          final idx = entry.key;
          final question = entry.value;
          final answer = _aiAnswers[idx];
          final isLoading = _isLoadingAnswer[idx] ?? false;

          return Card(
            color: context.colors.surface,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: context.colors.border)),
            child: ExpansionTile(
              title: Text('Q${idx + 1}: $question', style: context.textStyles.bodyMedium),
              iconColor: widget.themeColor,
              collapsedIconColor: context.colors.textSecondary,
              childrenPadding: const EdgeInsets.all(16),
              onExpansionChanged: (expanded) {
                if (expanded && answer == null && !isLoading) {
                  _getAIAnswer(idx, question);
                }
              },
              children: [
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (answer != null)
                  Text(answer, style: context.textStyles.bodyMedium.copyWith(color: context.colors.textSecondary))
              ],
            ),
          );
        }),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildProTip() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withOpacity(0.1), Colors.orange.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.lightbulb, color: Colors.amber),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pro Tip', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  _content!.proTip,
                  style: context.textStyles.bodyMedium.copyWith(color: context.colors.textMain),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }
}
