import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/quiz_model.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/groq_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/glass_card.dart';

class QuizScreen extends StatefulWidget {
  final String subject;
  final Color themeColor;
  final List<String> topics;

  const QuizScreen({
    super.key,
    required this.subject,
    required this.themeColor,
    required this.topics,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final GroqService _groqService = GroqService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  int? _selectedOption;

  @override
  void initState() {
    super.initState();
    _generateQuiz();
  }

  Future<void> _generateQuiz() async {
    final questions = await _groqService.generateQuiz(widget.subject, widget.topics);
    if (mounted) {
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    }
  }

  void _submitAnswer(int optionIndex) {
    if (_isAnswered) return;

    try {
      int correctIndex = -1;
      var correctVal = _questions[_currentIndex]['correct'];
      if (correctVal is int) {
        correctIndex = correctVal;
      } else if (correctVal is String) {
        correctIndex = int.tryParse(correctVal) ?? -1;
        if (correctIndex == -1) {
          final upper = correctVal.toUpperCase();
          if (upper == 'A') correctIndex = 0;
          if (upper == 'B') correctIndex = 1;
          if (upper == 'C') correctIndex = 2;
          if (upper == 'D') correctIndex = 3;
        }
      }

      final isCorrect = optionIndex == correctIndex;

      setState(() {
        _selectedOption = optionIndex;
        _isAnswered = true;
      });

      if (isCorrect) {
        _score++;
        context.read<UserProvider>().addXP(20);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: const Text('Correct! +20 XP'), backgroundColor: context.colors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: const Text('Incorrect.'), backgroundColor: context.colors.error),
        );
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          if (_currentIndex < _questions.length - 1) {
            setState(() {
              _currentIndex++;
              _isAnswered = false;
              _selectedOption = null;
            });
          } else {
            _finishQuiz();
          }
        }
      });
    } catch (e) {
      print('Submit answer error: $e');
    }
  }

  Future<void> _finishQuiz() async {
    final user = context.read<UserProvider>().user;
    if (user != null) {
      final quizModel = QuizModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        subject: widget.subject,
        score: _score,
        totalQuestions: _questions.length,
        takenAt: DateTime.now(),
      );
      await FirestoreService().saveQuizScore(user.uid, quizModel);
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: const Text('Quiz Complete!'),
        content: Text('You scored $_score out of ${_questions.length}.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('Done', style: TextStyle(color: widget.themeColor)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: context.colors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${widget.subject} Quiz', style: TextStyle(color: context.colors.textMain)),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: widget.themeColor),
                  const SizedBox(height: 16),
                  Text('AI is generating your custom quiz...', style: context.textStyles.bodyMedium),
                ],
              ),
            )
          : _questions.isEmpty
              ? Center(child: Text('Failed to generate quiz.', style: context.textStyles.bodyLarge))
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Question ${_currentIndex + 1}/${_questions.length}', style: context.textStyles.bodyMedium),
                          Text('Score: $_score', style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: (_currentIndex + 1) / _questions.length,
                        backgroundColor: context.colors.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _questions[_currentIndex]['question'],
                        style: context.textStyles.titleLarge.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: ListView.builder(
                          itemCount: (_questions[_currentIndex]['options'] as List).length,
                          itemBuilder: (context, index) {
                            final option = _questions[_currentIndex]['options'][index];
                            final isCorrect = index == _questions[_currentIndex]['correct'];
                            
                            Color buttonColor = context.colors.surface;
                            Color textColor = context.colors.textMain;
                            
                            if (_isAnswered) {
                              if (isCorrect) {
                                buttonColor = context.colors.success.withOpacity(0.2);
                                textColor = context.colors.success;
                              } else if (_selectedOption == index) {
                                buttonColor = context.colors.error.withOpacity(0.2);
                                textColor = context.colors.error;
                              }
                            } else if (_selectedOption == index) {
                              buttonColor = widget.themeColor.withOpacity(0.2);
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: GestureDetector(
                                onTap: () => _submitAnswer(index),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: buttonColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _isAnswered && isCorrect
                                          ? context.colors.success
                                          : _isAnswered && _selectedOption == index && !isCorrect
                                              ? context.colors.error
                                              : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    option,
                                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
