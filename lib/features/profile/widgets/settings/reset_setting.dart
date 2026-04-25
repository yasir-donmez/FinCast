import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../shared/widgets/precision_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../profile_list_items.dart';

class ResetSetting extends ConsumerWidget {
  const ResetSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ProfileListItems.buildSetting(
      icon: Icons.delete_forever_rounded,
      title: "Verileri Sıfırla",
      onTap: () => _showResetDialog(context, l10n),
      activeColor: AppColors.getExpense(context),
      context: context,
    );
  }

  void _showResetDialog(BuildContext context, AppLocalizations l10n) {
    showPrecisionDialog(
      context: context,
      title: "Verileri Sıfırla?",
      content: "Tüm finansal verileriniz ve ayarlarınız kalıcı olarak silinecek. Bu işlem geri alınamaz.",
      actions: [
        PrecisionDialogAction(
          label: "İptal",
          onTap: () => Navigator.pop(context),
          isPrimary: false,
        ),
        PrecisionDialogAction(
          label: "Hepsini Sil",
          onTap: () async {
            // Reset logic here
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Tüm veriler temizlendi")),
            );
          },
        ),
      ],
    );
  }
}
