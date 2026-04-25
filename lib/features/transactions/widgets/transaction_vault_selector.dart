import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/database/models/vault.dart';
import '../../../shared/widgets/fluid_sheet.dart';
import '../../../shared/widgets/precision_picker.dart';
import '../../../shared/widgets/precision_button.dart';

class TransactionVaultSelector extends StatelessWidget {
  final List<Vault> vaults;
  final List<int> selectedVaultIds;
  final ValueChanged<List<int>> onChanged;

  const TransactionVaultSelector({
    super.key,
    required this.vaults,
    required this.selectedVaultIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (vaults.isEmpty) return const SizedBox.shrink();
    
    final l10n = AppLocalizations.of(context)!;

    Vault? selectedVault;
    if (selectedVaultIds.isNotEmpty) {
      try {
        selectedVault = vaults.firstWhere(
          (v) => v.id == selectedVaultIds.first,
        );
      } catch (_) {}
    }

    final List<Vault?> vaultOptions = [null, ...vaults];

    int currentIndex = vaultOptions.indexWhere(
      (v) => selectedVaultIds.contains(v?.id),
    );
    if (currentIndex == -1) currentIndex = 0;


    return GestureDetector(
      onTap: () {
        int tempIndex = currentIndex;
        FluidSheet.show(
          context: context,
          title: l10n.selectVault,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrecisionPicker.strings(
                items: vaultOptions.map((v) => v?.name ?? l10n.generalBalance).toList(),
                initialItem: tempIndex,
                onSelectedItemChanged: (index) {
                  tempIndex = index;
                },
              ),
              const SizedBox(height: 32),
              PrecisionButton(
                label: l10n.ok,
                onTap: () {
                  final vid = vaultOptions[tempIndex]?.id;
                  if (vid != null) {
                    onChanged([vid]);
                  } else {
                    onChanged([]);
                  }
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                },
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.getPrimary(context).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
          border: Border.all(
            color: AppColors.getPrimary(context).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            selectedVault?.name ?? l10n.generalBalance,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: AppColors.getTextPrimary(context),
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

