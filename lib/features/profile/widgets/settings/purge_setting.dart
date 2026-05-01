import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/precision_inline_picker.dart';

class PurgeSetting extends ConsumerWidget {
  const PurgeSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permanentDays = ref.watch(settingsProvider.select((s) => s.permanentDeletionDays));
    final l10n = AppLocalizations.of(context)!;
    final expenseColor = AppColors.getExpense(context);

    final options = [
      {'label': l10n.oneMonth, 'days': 30},
      {'label': l10n.threeMonths, 'days': 90},
      {'label': l10n.sixMonths, 'days': 180},
      {'label': l10n.oneYear, 'days': 365},
      {'label': l10n.infinite, 'days': -1},
    ];

    final currentIndex = options.indexWhere((opt) => opt['days'] == permanentDays);

    // Çeviri kontrolü (fallback)
    String title = "Kalıcı Silme";
    try {
      // ignore: undefined_getter
      title = (l10n as dynamic).permanentDataDeletion ?? title;
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: expenseColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.delete_forever_rounded, color: expenseColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Veritabanından temizle",
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PrecisionInlinePicker(
            width: 80,
            height: 60,
            items: options.map((opt) => opt['label'] as String).toList(),
            selectedIndex: currentIndex != -1 ? currentIndex : 4, // Varsayılan sonsuz
            onChanged: (index) {
              ref.read(settingsProvider.notifier).setPermanentDeletion(options[index]['days'] as int);
            },
          ),
        ],
      ),
    );
  }
}
