import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GroqService {
  static const String _apiKey = 'YOUR_GROQ_API_KEY_HERE';
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  Future<String> callGroq(String prompt, {String? systemPrompt, List<Map<String, dynamic>>? history, String? imagePath}) async {
    try {
      final List<Map<String, dynamic>> messages = [];
      
      if (systemPrompt != null) {
        messages.add({'role': 'system', 'content': systemPrompt});
      }
      
      if (history != null) {
        messages.addAll(history);
      }
      
      if (prompt.isNotEmpty || imagePath != null) {
        if (imagePath != null) {
          final bytes = await File(imagePath).readAsBytes();
          final base64Image = base64Encode(bytes);
          messages.add({
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': prompt.isEmpty ? 'Analyze this image.' : prompt
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image'
                }
              }
            ]
          });
        } else {
          messages.add({'role': 'user', 'content': prompt});
        }
      }

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': imagePath != null ? 'llama-3.2-11b-vision-preview' : 'llama-3.3-70b-versatile',
          'messages': messages,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print('Groq API Error: ${response.body}');
        return 'Sorry, I am having trouble connecting to the AI Tutor right now.';
      }
    } catch (e) {
      print('Groq API Exception: $e');
      return 'An error occurred while connecting to the AI.';
    }
  }

  Future<String> getDailyMotivationalQuote(List<String> subjects) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      
      final savedDate = prefs.getString('quote_date');
      final savedQuote = prefs.getString('daily_quote');

      // Return cached quote if it's the same day
      if (savedDate == today && savedQuote != null && savedQuote.isNotEmpty) {
        return savedQuote;
      }

      final prompt = 'Give me a short, powerful, 1-sentence motivational quote for a student studying ${subjects.join(", ")}. Do not use quotes around the response, just the raw text.';
      final newQuote = await callGroq(prompt, systemPrompt: 'You are an inspiring mentor for CS students.');
      
      // Cache the new quote persistently
      if (!newQuote.contains('error') && !newQuote.contains('trouble connecting')) {
        await prefs.setString('quote_date', today);
        await prefs.setString('daily_quote', newQuote);
      }
      
      return newQuote;
    } catch (e) {
      return 'Keep pushing forward. Every expert was once a beginner.';
    }
  }

  Future<String> chatWithTutor(String subject, List<Map<String, dynamic>> history, {String? imagePath}) async {
    final systemPrompt = 'You are an expert AI tutor specializing in $subject. Your goal is to help a computer science student understand concepts deeply. Keep your answers concise, clear, and educational. Use markdown to format code blocks, lists, and emphasis.';
    
    // We pass the history, but if there's an imagePath, we don't pass the last prompt through history, we pass it directly to callGroq.
    // Wait, ai_tutor_screen already appended the user message to history. So we should pop it if there's an image.
    String prompt = '';
    if (imagePath != null && history.isNotEmpty && history.last['role'] == 'user') {
      prompt = history.last['content'] as String;
      prompt = prompt.replaceAll('[Image Attached] ', ''); // Clean prefix
      history.removeLast(); // Remove from simple history so callGroq can format it as a multimodal object
    }
    
    return await callGroq(prompt, systemPrompt: systemPrompt, history: history, imagePath: imagePath);
  }

  Future<String> compileCode(String code, String language) async {
    final systemPrompt = 'You are a strict $language compiler and executor. You receive $language code and you must return ONLY the raw console output of running that code. Do not include markdown blocks, do not explain the code. If there is a compilation error, return the exact $language compiler error. Do not output anything else.';
    final result = await callGroq(code, systemPrompt: systemPrompt);
    return result;
  }

  Future<List<String>> generateSyllabus(String subject) async {
    final systemPrompt = 'You are a syllabus generator. Return a comma-separated list of exactly 6 core topics to learn for "$subject". No numbers, no bullets, just a single comma-separated string like "Topic 1, Topic 2, Topic 3"';
    final result = await callGroq(subject, systemPrompt: systemPrompt);
    final topics = result.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (topics.isEmpty) return ['Introduction to $subject', 'Basic Concepts', 'Advanced Topics'];
    return topics;
  }

  Future<String> sendMessage(String subject, String message) async {
    return await chatWithTutor(subject, [{'role': 'user', 'content': message}]);
  }

  Future<Map<String, dynamic>> analyzeNote(String content) async {
    final systemPrompt = 'Analyze this study note. Return a valid JSON object strictly adhering to this schema: {"summary": "brief summary", "key_points": ["point 1", "point 2"], "difficulty": "Beginner|Intermediate|Advanced", "improvements": ["improvement 1"]}';
    final result = await callGroq(content, systemPrompt: systemPrompt);
    try {
      final jsonStr = result.substring(result.indexOf('{'), result.lastIndexOf('}') + 1);
      return jsonDecode(jsonStr);
    } catch (e) {
      return {
        "summary": "AI could not parse summary.",
        "key_points": ["Note recorded."],
        "difficulty": "Unknown",
        "improvements": ["Write clearer notes."]
      };
    }
  }

  Future<List<Map<String, dynamic>>> generateQuiz(String subject, List<String> topics) async {
    final topicStr = topics.isEmpty ? subject : topics.join(', ');
    final systemPrompt = 'Generate a 5-question multiple choice quiz on: $topicStr. Return strictly a JSON array of objects with schema: [{"question": "text", "options": ["A", "B", "C", "D"], "correct": 0}] where correct is the integer index (0-3) of the right option.';
    final result = await callGroq('Generate quiz', systemPrompt: systemPrompt);
    try {
      final jsonStr = result.substring(result.indexOf('['), result.lastIndexOf(']') + 1);
      final List<dynamic> parsed = jsonDecode(jsonStr);
      return parsed.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Groq Quiz Parse Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> generateTopicContent(String subject, String topic) async {
    final systemPrompt = '''You are an expert CS tutor. Teach the topic '$topic' from '$subject' to a university CS student. Structure your response in these exact sections:
1. OVERVIEW: 2-3 sentence simple explanation
2. KEY CONCEPTS: 4-6 bullet points of must-know concepts  
3. DETAILED EXPLANATION: full explanation with examples, minimum 200 words
4. CODE EXAMPLE: working code example with comments (C++ if CS topic)
5. COMMON MISTAKES: 3 bullet points of mistakes students make
6. PRACTICE QUESTIONS: 3 questions to test understanding
7. PRO TIP: one expert insight

Return strictly as a JSON object: {"overview": "...", "keyConcepts":["..."], "explanation": "...", "codeExample": "...", "commonMistakes":["..."], "practiceQuestions":["..."], "proTip": "..."}''';

    final result = await callGroq('Generate content', systemPrompt: systemPrompt);
    try {
      final jsonStr = result.substring(result.indexOf('{'), result.lastIndexOf('}') + 1);
      return jsonDecode(jsonStr);
    } catch (e) {
      print('Groq Topic Parse Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzeHandwriting(String base64Image) async {
    final systemPrompt = 'You are an expert AI extraction tool. The user provides a handwritten study note. Extract and organize all handwritten text. Identify the main topic and key points. Return strictly as a JSON object matching this schema: {"extractedText": "...", "organizedText": "...", "mainTopic": "...", "keyPoints":["..."]}';

    try {
      final List<Map<String, dynamic>> messages = [
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Analyze this handwritten note.'
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image'
              }
            }
          ]
        }
      ];

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.2-11b-vision-preview',
          'messages': messages,
          'max_tokens': 2048,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['choices'][0]['message']['content'];
        final jsonStr = result.substring(result.indexOf('{'), result.lastIndexOf('}') + 1);
        return jsonDecode(jsonStr);
      } else {
        print('Groq Vision Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Groq Vision Parse Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> reviewNoteContent(String content) async {
    final systemPrompt = '''You are an expert AI tutor. Analyze these study notes.
Return strictly as a JSON object matching this exact schema:
{
  "overallScore": 8,
  "strengths": ["..."],
  "weaknesses": ["..."],
  "missingConcepts": ["..."],
  "annotations": [
    {"lineOrPoint": "...", "comment": "...", "type": "good"},
    {"lineOrPoint": "...", "comment": "...", "type": "improve"},
    {"lineOrPoint": "...", "comment": "...", "type": "missing"}
  ],
  "studyTips": ["..."],
  "suggestedTopics": ["..."]
}

The 'type' in annotations must be strictly one of: 'good', 'improve', or 'missing'.''';

    final result = await callGroq('Analyze these notes:\n\n$content', systemPrompt: systemPrompt);
    try {
      final jsonStr = result.substring(result.indexOf('{'), result.lastIndexOf('}') + 1);
      return jsonDecode(jsonStr);
    } catch (e) {
      print('Groq Review Parse Error: $e');
      return null;
    }
  }
}
