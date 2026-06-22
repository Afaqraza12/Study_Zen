import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../models/note_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/groq_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/glass_card.dart';

class AIReviewSheet extends StatefulWidget {
  final NoteModel note;
  final String subject;
  final Color themeColor;

  const AIReviewSheet({
    super.key,
    required this.note,
    required this.subject,
    required this.themeColor,
  });

  @override
  State<AIReviewSheet> createState() => _AIReviewSheetState();
}

class _AIReviewSheetState extends State<AIReviewSheet> {
  final GroqService _groqService = GroqService();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isAnalyzing = false;
  Map<String, dynamic>? _reviewResult;

  @override
  void initState() {
    super.initState();
    if (widget.note.aiAnalysis != null) {
      _reviewResult = widget.note.aiAnalysis;
    } else {
      _generateReview();
    }
  }

  Future<void> _generateReview() async {
    setState(() => _isAnalyzing = true);
    
    final contentToAnalyze = widget.note.type == 'scanned' 
        ? 'Main Topic: ${widget.note.mainTopic}\n\nContent:\n${widget.note.organizedText}\n\nKey Points:\n${widget.note.keyPoints.join("\n")}'
        : widget.note.content;

    final result = await _groqService.reviewNoteContent(contentToAnalyze);
    
    if (result != null) {
      final user = context.read<UserProvider>().user;
      if (user != null) {
        final updatedNote = widget.note.copyWith(
          aiAnalysis: result,
          updatedAt: DateTime.now(),
        );
        await _firestoreService.saveNote(user.uid, updatedNote);
      }
    }
    
    if (mounted) {
      setState(() {
        _reviewResult = result;
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isAnalyzing
                    ? _buildLoadingState()
                    : _reviewResult == null
                        ? _buildErrorState()
                        : _buildReviewContent(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, color: widget.themeColor),
              const SizedBox(width: 12),
              Text('AI Note Review', style: context.textStyles.titleLarge),
            ],
          ),
          IconButton(
            icon: Icon(LucideIcons.x, color: context.colors.textMain),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(color: widget.themeColor, strokeWidth: 4),
                const Icon(LucideIcons.brainCircuit, size: 40, color: Colors.white54),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 4.seconds),
          const SizedBox(height: 32),
          Text('Analyzing your notes...', style: context.textStyles.titleLarge),
          const SizedBox(height: 8),
          Text('Evaluating understanding & identifying gaps', style: context.textStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertTriangle, size: 48, color: context.colors.error),
          const SizedBox(height: 16),
          Text('Failed to generate review.', style: context.textStyles.titleLarge),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _generateReview,
            style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewContent(ScrollController scrollController) {
    final score = _reviewResult!['overallScore'] ?? 0;
    Color scoreColor;
    String subtitle;
    if (score >= 8) {
      scoreColor = context.colors.success;
      subtitle = "Excellent! You've got a solid grasp on this.";
    } else if (score >= 5) {
      scoreColor = Colors.amber;
      subtitle = "Good start, but missing some key concepts.";
    } else {
      scoreColor = context.colors.error;
      subtitle = "Needs significant improvement. Let's study!";
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        // SCORE CARD
        Center(
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor, width: 8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$score/10',
                  style: context.textStyles.displayMedium.copyWith(color: scoreColor),
                ),
              ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms),
              const SizedBox(height: 16),
              Text(subtitle, style: context.textStyles.bodyLarge, textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // STRENGTHS
        if ((_reviewResult!['strengths'] as List).isNotEmpty) ...[
          _buildSectionHeader('Strengths', LucideIcons.checkCircle2, context.colors.success),
          ...(_reviewResult!['strengths'] as List).map((item) => _buildBulletPoint(item, context.colors.success)),
          const SizedBox(height: 24),
        ],

        // WEAKNESSES
        if ((_reviewResult!['weaknesses'] as List).isNotEmpty) ...[
          _buildSectionHeader('Needs Improvement', LucideIcons.alertTriangle, Colors.amber),
          ...(_reviewResult!['weaknesses'] as List).map((item) => _buildBulletPoint(item, Colors.amber)),
          const SizedBox(height: 24),
        ],

        // MISSING CONCEPTS
        if ((_reviewResult!['missingConcepts'] as List).isNotEmpty) ...[
          _buildSectionHeader('Missing Concepts', LucideIcons.xCircle, context.colors.error),
          ...(_reviewResult!['missingConcepts'] as List).map((item) => _buildBulletPoint(item, context.colors.error)),
          const SizedBox(height: 24),
        ],

        // ANNOTATIONS
        if ((_reviewResult!['annotations'] as List).isNotEmpty) ...[
          _buildSectionHeader('Detailed Annotations', LucideIcons.messageSquare, widget.themeColor),
          ...(_reviewResult!['annotations'] as List).map((anno) {
            final type = anno['type'];
            Color color = widget.themeColor;
            if (type == 'good') color = context.colors.success;
            else if (type == 'improve') color = Colors.amber;
            else if (type == 'missing') color = context.colors.error;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"${anno['lineOrPoint']}"', style: context.textStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  Text(anno['comment'], style: context.textStyles.bodySmall.copyWith(color: color)),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
        ],

        // STUDY TIPS
        if ((_reviewResult!['studyTips'] as List).isNotEmpty) ...[
          _buildSectionHeader('Study Tips', LucideIcons.lightbulb, Colors.orange),
          ...(_reviewResult!['studyTips'] as List).map((item) => _buildBulletPoint(item, Colors.orange)),
          const SizedBox(height: 24),
        ],
      ],
    ).animate().fadeIn();
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title, style: context.textStyles.titleLarge.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(LucideIcons.circle, size: 12, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: context.textStyles.bodyMedium)),
        ],
      ),
    );
  }
}
