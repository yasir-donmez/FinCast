import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;

    if (content.contains('AppColors.surface')) {
      content = content.replaceAll(
        'AppColors.surface',
        'AppColors.glassSurface',
      );
      changed = true;
    }
    if (content.contains('AppColors.border')) {
      content = content.replaceAll('AppColors.border', 'AppColors.glassBorder');
      changed = true;
    }
    if (content.contains('AppColors.divider')) {
      content = content.replaceAll(
        'AppColors.divider',
        'AppColors.glassBorderDark',
      );
      changed = true;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
