import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../database/database_service.dart';
import '../database/models/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseService.getSettings();
    state = settings;
    _updateIntl(state.languageCode);
  }

  Future<void> setThemeMode(int index) async {
    if (state.themeModeIndex == index) return;

    final newSettings = AppSettings()
      ..id = state.id
      ..themeModeIndex = index
      ..languageCode = state.languageCode
      ..dataRetentionDays = state.dataRetentionDays
      ..isAiNotificationsEnabled = state.isAiNotificationsEnabled;
    await _save(newSettings);
  }

  Future<void> setLanguage(String code) async {
    if (state.languageCode == code) return;

    final newSettings = AppSettings()
      ..id = state.id
      ..themeModeIndex = state.themeModeIndex
      ..languageCode = code
      ..dataRetentionDays = state.dataRetentionDays
      ..isAiNotificationsEnabled = state.isAiNotificationsEnabled;
    await _save(newSettings);
    _updateIntl(code);
  }

  void _updateIntl(String langCode) {
    String localeStr;
    switch (langCode) {
      case 'tr': localeStr = 'tr_TR'; break;
      case 'en': localeStr = 'en_US'; break;
      case 'de': localeStr = 'de_DE'; break;
      case 'es': localeStr = 'es_ES'; break;
      case 'fr': localeStr = 'fr_FR'; break;
      case 'pt': localeStr = 'pt_BR'; break;
      case 'it': localeStr = 'it_IT'; break;
      case 'ja': localeStr = 'ja_JP'; break;
      default: localeStr = 'en_US';
    }
    initializeDateFormatting(localeStr, null);
  }

  Future<void> setDataRetention(int days) async {
    final updated = AppSettings()
      ..id = state.id
      ..themeModeIndex = state.themeModeIndex
      ..languageCode = state.languageCode
      ..dataRetentionDays = days
      ..isAiNotificationsEnabled = state.isAiNotificationsEnabled;
    await _save(updated);
  }

  Future<void> toggleAiNotifications(bool value) async {
    final updated = AppSettings()
      ..id = state.id
      ..themeModeIndex = state.themeModeIndex
      ..languageCode = state.languageCode
      ..dataRetentionDays = state.dataRetentionDays
      ..isAiNotificationsEnabled = value;
    await _save(updated);
  }

  Future<void> _save(AppSettings settings) async {
    await DatabaseService.saveSettings(settings);
    // Directly assign the new state to notify listeners properly
    state = settings;
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
