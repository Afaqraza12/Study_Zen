import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/groq_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class NoteScanScreen extends StatefulWidget {
  final String subject;
  final Color themeColor;

  const NoteScanScreen({super.key, required this.subject, required this.themeColor});

  @override
  State<NoteScanScreen> createState() => _NoteScanScreenState();
}

class _NoteScanScreenState extends State<NoteScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final GroqService _groqService = GroqService();
  final FirestoreService _firestoreService = FirestoreService();

  File? _imageFile;
  String? _base64Image;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  final TextEditingController _extractedTextController = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _analysisResult = null;
        });
        await _compressAndAnalyze();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _compressAndAnalyze() async {
    if (_imageFile == null) return;
    setState(() => _isAnalyzing = true);

    try {
      final bytes = await _imageFile!.readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 800,
        quality: 70,
      );
      
      _base64Image = base64Encode(compressed);

      final result = await _groqService.analyzeHandwriting(_base64Image!);
      
      if (result != null) {
        setState(() {
          _analysisResult = result;
          _extractedTextController.text = result['extractedText'] ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to analyze note. Please try again.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _saveNote() async {
    if (_analysisResult == null || _base64Image == null) return;

    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final note = NoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: widget.subject,
      title: _analysisResult!['mainTopic'] ?? 'Scanned Note',
      content: _extractedTextController.text, // User can edit extracted text
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      type: 'scanned',
      organizedText: _analysisResult!['organizedText'] ?? '',
      keyPoints: List<String>.from(_analysisResult!['keyPoints'] ?? []),
      originalImageBase64: _base64Image!,
      mainTopic: _analysisResult!['mainTopic'] ?? '',
    );

    await _firestoreService.saveNote(user.uid, note);
    context.read<UserProvider>().addXP(10); // Reward for scanning a note!
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Scan Note'),
        backgroundColor: widget.themeColor,
        actions: [
          if (_analysisResult != null)
            TextButton(
              onPressed: _saveNote,
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _imageFile == null ? _buildImagePicker() : _buildAnalysisView(),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.camera, size: 80, color: widget.themeColor.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text('Capture your handwritten notes', style: context.textStyles.titleLarge),
          const SizedBox(height: 8),
          Text('Our AI will extract and organize them for you.', style: context.textStyles.bodyMedium),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(LucideIcons.camera),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(LucideIcons.image),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(backgroundColor: context.colors.surface),
              ),
            ],
          )
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildAnalysisView() {
    return Column(
      children: [
        // Top half: Image preview
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(_imageFile!, fit: BoxFit.contain),
                if (_isAnalyzing)
                  Container(
                    color: Colors.black54,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        Text('Reading your handwriting...', style: context.textStyles.bodyLarge.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Bottom half: Extracted text editable
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: _isAnalyzing 
                ? _buildLoadingSkeletons()
                : _analysisResult == null 
                    ? const Center(child: Text('Analysis failed'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Extracted Text', style: context.textStyles.titleLarge),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: widget.themeColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('Edit if needed', style: TextStyle(color: widget.themeColor, fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: TextField(
                              controller: _extractedTextController,
                              maxLines: null,
                              expands: true,
                              style: context.textStyles.bodyMedium,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                fillColor: context.colors.surface,
                                filled: true,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeletons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 150, height: 24, color: context.colors.surface),
        const SizedBox(height: 16),
        Container(width: double.infinity, height: 16, color: context.colors.surface),
        const SizedBox(height: 8),
        Container(width: double.infinity, height: 16, color: context.colors.surface),
        const SizedBox(height: 8),
        Container(width: 200, height: 16, color: context.colors.surface),
      ],
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(begin: 0.3, end: 0.8);
  }
}
