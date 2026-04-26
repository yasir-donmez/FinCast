import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../shared/widgets/precision_sheet.dart';
import '../../../../shared/widgets/precision_picker.dart';
import '../../../../shared/widgets/precision_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dashboard/dashboard_providers.dart';
import '../profile_list_items.dart';

class CurrencySetting extends ConsumerWidget {
  const CurrencySetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final activeColor = ref.watch(rotaryColorProvider);
    final l10n = AppLocalizations.of(context)!;

    return ProfileListItems.buildSetting(
      icon: Icons.currency_lira_rounded,
      title: "Para Birimi",
      trailing: settings.currencySymbol,
      onTap: () => _showCurrencyPicker(context, ref, settings.currencySymbol, l10n),
      activeColor: activeColor,
      context: context,
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, String currentSymbol, AppLocalizations l10n) {
    HapticFeedback.lightImpact();
    final activeColor = ref.read(rotaryColorProvider);
    final currencies = AppCurrency.supportedSymbols;
    int initialIndex = currencies.indexOf(currentSymbol);
    if (initialIndex == -1) initialIndex = 0;

    int tempIndex = initialIndex;

    PrecisionSheet.show(
      context: context,
      title: l10n.selectCurrency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrecisionPicker.strings(
            items: currencies,
            initialItem: initialIndex,
            onSelectedItemChanged: (index) => tempIndex = index,
          ),
          const SizedBox(height: 32),
          PrecisionButton(
            label: l10n.ok,
            onTap: () {
              ref.read(settingsProvider.notifier).setCurrency(currencies[tempIndex]);
              Navigator.pop(context);
            },
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }
}
