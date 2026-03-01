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

    if (content.contains('AppColors.glassSurface')) {
      content = content.replaceAll(
        'AppColors.glassSurface',
        'AppColors.surface',
      );
      changed = true;
    }
    if (content.contains('AppColors.glassBorderDark')) {
      content = content.replaceAll(
        'AppColors.glassBorderDark',
        'AppColors.darkShadow',
      );
      changed = true;
    }
    if (content.contains('AppColors.glassBorder')) {
      content = content.replaceAll(
        'AppColors.glassBorder',
        'AppColors.lightShadow',
      );
      changed = true;
    }
    if (content.contains('AppColors.backgroundStart')) {
      content = content.replaceAll(
        'AppColors.backgroundStart',
        'AppColors.background',
      );
      changed = true;
    }
    if (content.contains('AppColors.backgroundMid')) {
      content = content.replaceAll(
        'AppColors.backgroundMid',
        'AppColors.background',
      );
      changed = true;
    }
    if (content.contains('AppColors.backgroundEnd')) {
      content = content.replaceAll(
        'AppColors.backgroundEnd',
        'AppColors.background',
      );
      changed = true;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
