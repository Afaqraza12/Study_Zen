import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:photo_view/photo_view.dart';
import '../../models/note_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../ai_tutor/ai_tutor_screen.dart';
import 'note_editor_screen.dart';
import 'widgets/ai_review_sheet.dart';

class NoteDetailScreen extends StatefulWidget {
  final NoteModel note;
  final String subject;
  final Color themeColor;

  const NoteDetailScreen({
    super.key,
    required this.note,
    required this.subject,
    required this.themeColor,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isScanned = widget.note.type == 'scanned';

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(isScanned ? widget.note.mainTopic : widget.note.title),
        backgroundColor: widget.themeColor,
        actions: [
          if (!isScanned)
            IconButton(
              icon: const Icon(LucideIcons.edit3),
              tooltip: 'Edit Note',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoteEditorScreen(
                      subject: widget.subject,
                      themeColor: widget.themeColor,
                      existingNote: widget.note,
                    ),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(LucideIcons.sparkles),
            tooltip: 'AI Review',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AIReviewSheet(
                  note: widget.note,
                  subject: widget.subject,
                  themeColor: widget.themeColor,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (isScanned && widget.note.originalImageBase64.isNotEmpty)
            _buildImageHeader(),
          
          if (isScanned)
            _buildTabBar(),
            
          Expanded(
            child: isScanned 
              ? _buildScannedContent() 
              : _buildTypedContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHeader() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: PhotoView(
            imageProvider: MemoryImage(base64Decode(widget.note.originalImageBase64)),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        )));
      },
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              base64Decode(widget.note.originalImageBase64),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(LucideIcons.maximize2, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Tap to expand', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Extracted Text', 'Key Points', 'AI Tutor'];
    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(tabs.length, (index) {
          final isActive = _currentTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _currentTabIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? widget.themeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  color: isActive ? Colors.white : context.colors.textSecondary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScannedContent() {
    switch (_currentTabIndex) {
      case 0:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.note.organizedText.isEmpty ? widget.note.content : widget.note.organizedText,
            style: context.textStyles.bodyMedium.copyWith(height: 1.6),
          ).animate().fadeIn(),
        );
      case 1:
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: widget.note.keyPoints.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.checkCircle2, color: widget.themeColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.note.keyPoints[index], style: context.textStyles.bodyMedium),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
          },
        );
      case 2:
        return AITutorScreen(
          selectedSubject: widget.subject,
          themeColor: widget.themeColor,
          initialContext: 'Context Note: ${widget.note.mainTopic}\n\n${widget.note.organizedText}',
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildTypedContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Text(
        widget.note.content,
        style: context.textStyles.bodyMedium.copyWith(height: 1.6),
      ).animate().fadeIn(),
    );
  }
}
