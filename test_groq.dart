import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer YOUR_GROQ_API_KEY_HERE',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': 'llama-3.3-70b-versatile',
      'messages': [{'role': 'user', 'content': 'Test'}],
    }),
  );
  
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}
