import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    if (file.path.contains('app_colors.dart') || 
        file.path.contains('app_text_styles.dart') || 
        file.path.contains('theme_provider.dart') ||
        file.path.contains('app_theme.dart')) {
      continue;
    }
    
    String content = file.readAsStringSync();
    bool modified = false;

    if (content.contains('AppColors.')) {
      content = content.replaceAll('AppColors.', 'context.colors.');
      modified = true;
    }

    if (content.contains('AppTextStyles.')) {
      content = content.replaceAll('AppTextStyles.', 'context.textStyles.');
      modified = true;
    }

    if (modified) {
      file.writeAsStringSync(content);
      print('Updated \${file.path}');
    }
  }
}
