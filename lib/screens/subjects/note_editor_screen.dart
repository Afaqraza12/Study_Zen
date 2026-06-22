import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/note_model.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class NoteEditorScreen extends StatefulWidget {
  final String subject;
  final Color themeColor;
  final NoteModel? existingNote;

  const NoteEditorScreen({
    super.key,
    required this.subject,
    required this.themeColor,
    this.existingNote,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController = TextEditingController(text: widget.existingNote?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_titleController.text != (widget.existingNote?.title ?? '') ||
        _contentController.text != (widget.existingNote?.content ?? '')) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: context.colors.surface,
          title: const Text('Discard Changes?'),
          content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Discard', style: TextStyle(color: context.colors.error)),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content cannot be empty.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    final user = context.read<UserProvider>().user;
    if (user != null) {
      final isNew = widget.existingNote == null;
      final note = NoteModel(
        id: widget.existingNote?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        subject: widget.subject,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: widget.existingNote?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        aiAnalysis: widget.existingNote?.aiAnalysis,
      );

      await FirestoreService().saveNote(user.uid, note);
      
      if (isNew) {
        // Basic daily check logic could be more complex, but we'll award 5 XP once
        context.read<UserProvider>().addXP(5);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note saved! +5 XP 📝'),
            backgroundColor: widget.themeColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note updated!'),
            backgroundColor: widget.themeColor,
          ),
        );
      }
    }
    
    setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.x, color: context.colors.textMain),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveNote,
                icon: _isSaving 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(LucideIcons.save, color: Colors.white, size: 18),
                label: const Text('Save', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                child: TextField(
                  controller: _titleController,
                  style: context.textStyles.displayMedium.copyWith(fontSize: 24),
                  decoration: InputDecoration(
                    hintText: 'Note Title',
                    hintStyle: context.textStyles.displayMedium.copyWith(
                      fontSize: 24,
                      color: context.colors.textSecondary.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TextField(
                    controller: _contentController,
                    style: context.textStyles.bodyLarge.copyWith(height: 1.6),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'Start typing your notes here...',
                      hintStyle: context.textStyles.bodyLarge.copyWith(
                        color: context.colors.textSecondary.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
