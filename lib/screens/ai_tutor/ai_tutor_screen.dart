import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../providers/user_provider.dart';
import '../../services/groq_service.dart';
import '../../services/firestore_service.dart';
import '../../models/chat_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AITutorScreen extends StatefulWidget {
  final String selectedSubject;
  final String? existingSessionId;
  final Color? themeColor;
  final String? initialContext;

  const AITutorScreen({
    super.key,
    required this.selectedSubject,
    this.existingSessionId,
    this.themeColor,
    this.initialContext,
  });

  @override
  State<AITutorScreen> createState() => _AITutorScreenState();
}

class _AITutorScreenState extends State<AITutorScreen> {
  final GroqService _groqService = GroqService();
  final FirestoreService _firestoreService = FirestoreService();
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late ChatSession _chatSession;
  bool _isTyping = false;
  bool _isSessionInitialized = false;

  final List<String> _quickQuestions = [
    "Explain Pointers",
    "Big O Notation",
    "What is OSPF",
    "Recursion basics"
  ];

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;

    if (widget.existingSessionId != null) {
      final session = await _firestoreService.getChatSession(user.uid, widget.existingSessionId!);
      if (session != null) {
        setState(() {
          _chatSession = session;
          _isSessionInitialized = true;
        });
        _scrollToBottom();
        return;
      }
    }

    setState(() {
      _chatSession = ChatSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        subject: widget.selectedSubject,
        title: '${widget.selectedSubject} Session',
        messages: [
          if (widget.initialContext != null)
            ChatMessage(
              role: 'system',
              content: widget.initialContext!,
              timestamp: DateTime.now(),
            ),
          ChatMessage(
            role: 'ai',
            content: 'Hello! I am your AI Tutor for **${widget.selectedSubject}**. ${widget.initialContext != null ? "I have reviewed your note." : "How can I help you today?"}',
            timestamp: DateTime.now(),
          ),
        ],
        lastUpdated: DateTime.now(),
      );
      _isSessionInitialized = true;
    });
    
    await _firestoreService.saveChatSession(user.uid, _chatSession);
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      role: 'user',
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _chatSession.messages.add(userMessage);
      _chatSession.lastUpdated = DateTime.now();
      if (_chatSession.messages.length == 3) {
        _chatSession.title = text.trim().length > 20 
            ? '${text.trim().substring(0, 20)}...' 
            : text.trim();
      }
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      await _firestoreService.saveChatSession(user.uid, _chatSession);
    }

    try {
      final history = _chatSession.messages.map((m) => {
        'role': m.role,
        'content': m.content
      }).toList();
      
      final aiResponse = await _groqService.chatWithTutor(widget.selectedSubject, history);
      
      final aiMessage = ChatMessage(
        role: 'ai',
        content: aiResponse,
        timestamp: DateTime.now(),
      );

      setState(() {
        _chatSession.messages.add(aiMessage);
        _chatSession.lastUpdated = DateTime.now();
        _isTyping = false;
      });

      if (user != null) {
        await _firestoreService.saveChatSession(user.uid, _chatSession);
      }
      
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get response from AI.')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveThemeColor = widget.themeColor ?? context.colors.primary;
    
    if (!_isSessionInitialized) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: context.colors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _chatSession.title,
          style: context.textStyles.titleLarge,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: context.colors.border, height: 1),
        ),
      ),
      body: Stack(
        children: [
          // Dot Grid Background pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/cubes.png', // Fallback pattern
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  itemCount: _chatSession.messages.length,
                  itemBuilder: (context, index) {
                    final message = _chatSession.messages[index];
                    if (message.role == 'system') return const SizedBox.shrink();
                    return _buildMessageBubble(message, effectiveThemeColor);
                  },
                ),
              ),
              
              if (_isTyping)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: _buildTypingIndicator(effectiveThemeColor),
                ),
              
              if (_chatSession.messages.length <= 1) _buildQuickQuestions(effectiveThemeColor),

              _buildInputArea(effectiveThemeColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions(Color effectiveThemeColor) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _quickQuestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ActionChip(
              backgroundColor: context.colors.surface,
              side: BorderSide(color: effectiveThemeColor.withOpacity(0.5)),
              label: Text(_quickQuestions[index], style: TextStyle(color: context.colors.textMain)),
              onPressed: () => _sendMessage(_quickQuestions[index]),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 400 + (index * 100)));
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, Color effectiveThemeColor) {
    final isUser = message.role == 'user';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: effectiveThemeColor.withOpacity(0.2),
                border: Border.all(color: effectiveThemeColor),
              ),
              child: Icon(LucideIcons.bot, color: effectiveThemeColor, size: 18),
            ),
            SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isUser ? effectiveThemeColor : context.colors.surface,
                gradient: isUser ? LinearGradient(
                  colors: [effectiveThemeColor, effectiveThemeColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ) : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: isUser ? null : Border.all(color: context.colors.border),
                boxShadow: isUser ? [
                  BoxShadow(
                    color: effectiveThemeColor.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: isUser ? Colors.white : context.colors.textMain, fontSize: 16, height: 1.5),
                  code: context.textStyles.code.copyWith(
                    backgroundColor: context.colors.background,
                    color: effectiveThemeColor,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFF0D0D14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.border),
                  ),
                ),
              ),
            ),
          ),
          if (isUser) SizedBox(width: 44),
        ],
      ).animate().fadeIn().slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildTypingIndicator(Color effectiveThemeColor) {
    return Container(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: effectiveThemeColor.withOpacity(0.2),
              border: Border.all(color: effectiveThemeColor),
            ),
            child: Icon(LucideIcons.bot, color: effectiveThemeColor, size: 18),
          ),
          SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: context.colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0, effectiveThemeColor),
                _buildDot(1, effectiveThemeColor),
                _buildDot(2, effectiveThemeColor),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildDot(int index, Color effectiveThemeColor) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: effectiveThemeColor.withOpacity(0.4 + (0.6 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea(Color effectiveThemeColor) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 32),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.background,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: context.colors.border),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: context.colors.textMain),
                decoration: InputDecoration(
                  hintText: 'Message AI Tutor...',
                  hintStyle: TextStyle(color: context.colors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(LucideIcons.mic, color: context.colors.textSecondary),
                    onPressed: () {},
                  ),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: effectiveThemeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: effectiveThemeColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(LucideIcons.send, color: Colors.white, size: 20),
            ),
          ).animate().scale(curve: Curves.easeOutBack),
        ],
      ),
    );
  }
}
