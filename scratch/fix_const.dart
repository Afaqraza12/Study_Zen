import 'dart:io';

void main() {
  final files = Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  for (var file in files) {
    if (file.path.contains('theme_provider.dart')) continue;
    String content = file.readAsStringSync();
    content = content.replaceAll('const TextStyle(', 'TextStyle(');
    content = content.replaceAll('const Icon(', 'Icon(');
    content = content.replaceAll('const BorderSide(', 'BorderSide(');
    content = content.replaceAll('const Center(', 'Center(');
    content = content.replaceAll('const Text(', 'Text(');
    content = content.replaceAll('const Padding(', 'Padding(');
    content = content.replaceAll('const SizedBox(', 'SizedBox(');
    content = content.replaceAll('const BoxDecoration(', 'BoxDecoration(');
    content = content.replaceAll('const UnderlineInputBorder(', 'UnderlineInputBorder(');
    content = content.replaceAll('const AlwaysStoppedAnimation', 'AlwaysStoppedAnimation');
    content = content.replaceAll('const SnackBar(', 'SnackBar(');
    file.writeAsStringSync(content);
  }
}
