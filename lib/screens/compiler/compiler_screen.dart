import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../services/groq_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../services/compiler_service.dart';
import '../../services/firestore_service.dart';
import '../../models/snippet_model.dart';

class CompilerScreen extends StatefulWidget {
  const CompilerScreen({super.key});

  @override
  State<CompilerScreen> createState() => _CompilerScreenState();
}

class _CompilerScreenState extends State<CompilerScreen> {
  final TextEditingController _codeController = TextEditingController();
  final CompilerService _compilerService = CompilerService();
  
  String _output = 'Console ready...\n';
  bool _isRunning = false;

  final String _defaultCode = '''#include <iostream>
using namespace std;

int main() {
    cout << "Hello, World!" << endl;
    return 0;
}''';

  @override
  void initState() {
    super.initState();
    _codeController.text = _defaultCode;
  }

  void _runCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isRunning = true;
      _output = 'Running...\n';
    });

    try {
      final result = await _compilerService.compileAndRun(code, 'C++');
      
      setState(() {
        _output = result;
        _isRunning = false;
      });

      // Award XP for running code
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).addXP(5);
      }
    } catch (e) {
      setState(() {
        _output = 'Error executing code: $e';
        _isRunning = false;
      });
    }
  }

  void _clearCode() {
    setState(() {
      _codeController.clear();
      _output = 'Console ready...\n';
    });
  }

  void _resetCode() {
    setState(() {
      _codeController.text = _defaultCode;
      _output = 'Console ready...\n';
    });
  }

  void _aiCodeReview() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    
    setState(() {
      _output = 'Analyzing code...\n';
      _isRunning = true;
    });

    final analysis = await _compilerService.aiCodeReview(code, 'C++');
    
    setState(() {
      _output = analysis;
      _isRunning = false;
    });
  }

  void _saveSnippet() {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final TextEditingController titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: const Text('Save Snippet'),
        content: TextField(
          controller: titleController,
          style: TextStyle(color: context.colors.textMain),
          decoration: InputDecoration(
            hintText: 'Snippet Title',
            hintStyle: TextStyle(color: context.colors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              Navigator.pop(ctx);
              
              final user = context.read<UserProvider>().user;
              if (user != null) {
                final snippet = SnippetModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: titleController.text,
                  code: code,
                  language: 'C++',
                  savedAt: DateTime.now(),
                );
                await FirestoreService().saveSnippet(user.uid, snippet);
                context.read<UserProvider>().addXP(15);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Snippet saved! +15 XP'), backgroundColor: context.colors.success),
                );
              }
            },
            child: Text('Save', style: TextStyle(color: context.colors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 120.0), // Padding for floating nav
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Compiler', style: context.textStyles.displayMedium).animate().fadeIn().slideY(begin: -0.1, end: 0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.colors.primaryGlow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.colors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.code2, color: context.colors.primary, size: 16),
                        SizedBox(width: 8),
                        Text('C++', style: context.textStyles.bodyMedium.copyWith(color: context.colors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              // Toolbar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildToolbarButton(LucideIcons.rotateCcw, 'Reset', _resetCode),
                    const SizedBox(width: 12),
                    _buildToolbarButton(LucideIcons.eraser, 'Clear', _clearCode),
                    const SizedBox(width: 12),
                    _buildToolbarButton(LucideIcons.sparkles, 'AI Review', _aiCodeReview),
                    const SizedBox(width: 12),
                    _buildToolbarButton(LucideIcons.save, 'Save', _saveSnippet),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),

              // Code Editor
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D14), // Darker surface for editor
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: TextField(
                      controller: _codeController,
                      maxLines: null,
                      expands: true,
                      style: context.textStyles.code,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                        hintText: '// Write your C++ code here',
                        hintStyle: context.textStyles.code.copyWith(color: context.colors.textSecondary.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.98, 0.98)),
              ),
              
              SizedBox(height: 16),
              
              GradientButton(
                text: 'Run Code',
                icon: LucideIcons.play,
                isLoading: _isRunning,
                onPressed: _runCode,
              ).animate().fadeIn(delay: 300.ms),

              SizedBox(height: 16),

              // Console Output
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050508), // Almost black for console
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _output,
                      style: context.textStyles.code.copyWith(
                        color: _output.contains('Error') || _output.contains('Failed') 
                            ? context.colors.error 
                            : (_output == 'Console ready...\n' || _output == 'Running...\n' ? context.colors.textSecondary : context.colors.success),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 12,
        child: Row(
          children: [
            Icon(icon, color: context.colors.textSecondary, size: 16),
            SizedBox(width: 8),
            Text(label, style: context.textStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
