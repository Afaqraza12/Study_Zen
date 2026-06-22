import 'dart:convert';
import 'package:http/http.dart' as http;
import 'groq_service.dart';

class CompilerService {
  final GroqService _groqService = GroqService();

  Future<String> compileAndRun(String code, String language) async {
    // Attempt Judge0 API
    try {
      final url = Uri.parse('https://ce.judge0.com/submissions?base64_encoded=false&wait=false');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'source_code': code,
          'language_id': 54, // 54 = C++ (GCC 9.2.0)
        }),
      );

      if (response.statusCode == 201) {
        final token = jsonDecode(response.body)['token'];
        
        // Polling
        while (true) {
          await Future.delayed(const Duration(seconds: 1));
          final pollRes = await http.get(Uri.parse('https://ce.judge0.com/submissions/$token?base64_encoded=false'));
          
          if (pollRes.statusCode == 200) {
            final data = jsonDecode(pollRes.body);
            final status = data['status']['id'];
            
            if (status <= 2) continue; // 1 = In Queue, 2 = Processing
            
            if (status == 3) {
              return data['stdout']?.toString() ?? 'Successfully executed with no output';
            } else if (status == 6) {
              return 'Compilation Error:\n${data['compile_output']}';
            } else {
              return data['stderr']?.toString() ?? data['compile_output']?.toString() ?? 'Execution error (Status: $status)';
            }
          } else {
            break; // Break polling loop on error to trigger fallback
          }
        }
      }
    } catch (e) {
      print('Judge0 Exception: $e');
    }

    // Fallback to Groq if Judge0 fails or is rate limited
    return await _groqFallback(code, language);
  }

  Future<String> _groqFallback(String code, String language) async {
    final systemPrompt = '''
You are a strict, ultra-fast, command-line $language compiler.
The user will provide you with raw $language source code.
Your ONLY job is to execute the code mentally and output the exact stdout terminal output.
If there are compilation errors or syntax errors, output the exact stderr compiler error messages.

RULES:
1. Do NOT explain the output.
2. Do NOT say "Here is the output".
3. Do NOT use markdown code blocks like ``` around your output.
4. ONLY output exactly what a terminal would print if this code was executed via `g++ main.cpp && ./a.out`.
5. If the code requires user input (cin/scanf), assume the user provided generic valid input, but mention it in the output.
''';

    try {
      final response = await _groqService.callGroq(
        code,
        systemPrompt: systemPrompt,
      );
      return response.trim();
    } catch (e) {
      return 'Error: Could not reach the compiler engine.\nDetails: $e';
    }
  }

  Future<String> aiCodeReview(String code, String language) async {
    final systemPrompt = 'Review the following $language code. Point out any bugs, performance issues, or bad practices. Then provide a cleaner, optimized version of the code. Keep it concise.';
    try {
      return await _groqService.callGroq(code, systemPrompt: systemPrompt);
    } catch (e) {
      return 'Failed to analyze code.';
    }
  }
}
