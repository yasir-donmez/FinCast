import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../shared/widgets/fluid_sheet.dart';
import '../../../../shared/widgets/precision_picker.dart';
import '../../../../shared/widgets/precision_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dashboard/dashboard_providers.dart';
import '../profile_list_items.dart';

class LanguageSetting extends ConsumerWidget {
  const LanguageSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final activeColor = ref.watch(rotaryColorProvider);
    final l10n = AppLocalizations.of(context)!;

    return ProfileListItems.buildSetting(
      icon: Icons.language_rounded,
      title: l10n.language,
      trailing: _getLanguageName(settings.languageCode),
      onTap: () => _showLanguagePicker(context, ref, settings.languageCode, l10n),
      activeColor: activeColor,
      context: context,
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, String currentCode, AppLocalizations l10n) {
    final List<String> languages = ["Türkçe", "English", "Deutsch", "Español", "Français", "Português", "Italiano", "日本語"];
    final List<String> codes = ["tr", "en", "de", "es", "fr", "pt", "it", "ja"];
    int initialIndex = codes.indexOf(currentCode);
    if (initialIndex == -1) initialIndex = 0;

    FluidSheet.show(
      context: context,
      title: l10n.selectLanguage,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrecisionPicker.strings(
            items: languages,
            initialItem: initialIndex,
            onSelectedItemChanged: (index) {
              HapticFeedback.selectionClick();
              ref.read(settingsProvider.notifier).setLanguage(codes[index]);
            },
          ),
          const SizedBox(height: 24),
          PrecisionButton(
            label: l10n.ok,
            onTap: () => Navigator.pop(context),
            activeColor: ref.read(rotaryColorProvider),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'tr': return 'Türkçe';
      case 'en': return 'English';
      case 'de': return 'Deutsch';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      case 'pt': return 'Português';
      case 'it': return 'Italiano';
      case 'ja': return '日本語';
      default: return 'Türkçe';
    }
  }
}
