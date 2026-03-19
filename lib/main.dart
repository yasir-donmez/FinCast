import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'l10n/app_localizations.dart';
import 'features/dashboard/main_scaffold.dart';
import 'core/database/database_service.dart';
import 'core/theme/app_theme.dart';
import 'core/services/data_retention_service.dart';
import 'core/providers/settings_provider.dart';

void main() async {
  try {
    debugPrint('🚀 [FinCast] Uygulama başlatılıyor...');
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('✅ [FinCast] Flutter Binding hazır.');

    // Isar veritabanını başlat
    debugPrint('📦 [FinCast] Veritabanı başlatılıyor...');
    await DatabaseService.init();
    debugPrint('✅ [FinCast] Veritabanı başarıyla başlatıldı.');

    // Süresi dolan işlemleri arşivle
    debugPrint('🧹 [FinCast] Arşivleme işlemi başlatılıyor...');
    await DataRetentionService.archiveExpiredTransactions();
    debugPrint('✅ [FinCast] Arşivleme tamamlandı.');

    // Varsayılan dil ayarı
    debugPrint('🌍 [FinCast] Yerelleştirme başlatılıyor...');
    await initializeDateFormatting('tr_TR', null);
    debugPrint('✅ [FinCast] Yerelleştirme hazır.');

    debugPrint('🏁 [FinCast] runApp() çağrılıyor...');
    runApp(
      const ProviderScope(child: FinCastApp()),
    );
  } catch (e, stack) {
    debugPrint('❌ [FinCast FATAL] Başlangıç hatası: $e');
    debugPrint('📜 [FinCast FATAL] Stack Trace:\n$stack');
    
    // Uygulama kritik bir hata aldığında en azından bir hata ekranı gösterelim
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SelectableText(
                'Kritik Başlangıç Hatası\n\n$e\n\n$stack',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FinCastApp extends ConsumerWidget {
  const FinCastApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = _getThemeMode(settings.themeModeIndex);

    // Dil kodunu temizle (tr_TR -> tr)
    final langCode = settings.languageCode.split('_')[0].toLowerCase();
    
    // Geçerli bir locale nesnesi oluştur, hata durumunda varsayılan 'tr'
    Locale? appLocale;
    try {
      if (langCode.isNotEmpty) {
        appLocale = Locale(langCode);
      }
    } catch (_) {}
    appLocale ??= const Locale('tr');

    return MaterialApp(
      title: 'FinCast',
      debugShowCheckedModeBanner: false,

      // Tema Yapılandırması (Karanlık Neumorphism)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      
      // Dil Yapılandırması
      locale: appLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      home: const MainScaffold(),
    );
  }

  ThemeMode _getThemeMode(int index) {
    switch (index) {
      case 0: return ThemeMode.system;
      case 1: return ThemeMode.light;
      case 2: return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }
}
