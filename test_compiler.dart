import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://emacs.piston.rs/api/v2/execute');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'language': 'cpp',
        'version': '10.2.0',
        'files': [
          {
            'content': '#include <iostream>\nint main() { std::cout << "Hello C++"; return 0; }'
          }
        ]
      }),
    );
    print('emacs.piston.rs Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('emacs.piston.rs Failed: $e');
  }

  // Also test standard piston
  final url2 = Uri.parse('https://piston.pterodactyl.io/api/v2/execute');
  try {
    final response = await http.post(
      url2,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'language': 'cpp',
        'version': '10.2.0',
        'files': [
          {
            'content': '#include <iostream>\nint main() { std::cout << "Hello C++ 2"; return 0; }'
          }
        ]
      }),
    );
    print('piston.pterodactyl.io Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('piston.pterodactyl.io Failed: $e');
  }
}
