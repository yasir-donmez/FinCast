import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/dashboard/main_scaffold.dart';

import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Isar veritabanı ileride burada başlatılacak (Aşama 5)
  // await DatabaseService.init();

  runApp(
    // Riverpod State Management için En Üst Kapsayıcı
    const ProviderScope(child: FinCastApp()),
  );
}

class FinCastApp extends StatelessWidget {
  const FinCastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinCast',
      debugShowCheckedModeBanner: false,

      // Tema Yapılandırması (Karanlık Neumorphism)
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Sisteme bakmaksızın her zaman karanlık

      home: const MainScaffold(),
    );
  }
}
