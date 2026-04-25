import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/database/models/vault.dart';
import '../../../shared/widgets/fluid_sheet.dart';
import '../../../shared/widgets/precision_clickable.dart';

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

    IconData getIconData(String? code) {
      if (code == null) return Icons.account_balance_wallet_rounded;
      switch (code) {
        case 'account_balance_wallet_rounded':
          return Icons.account_balance_wallet_rounded;
        case 'attach_money_rounded':
          return Icons.attach_money_rounded;
        case 'diamond_rounded':
          return Icons.diamond_rounded;
        default:
          return Icons.account_balance_wallet_rounded;
      }
    }

    return GestureDetector(
      onTap: () {
        int tempIndex = currentIndex;
        FluidSheet.show(
          context: context,
          title: l10n.selectVault,
          height: 350,
          child: StatefulBuilder(
            builder: (context, setPickerState) {
              return Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 50,
                      perspective: 0.006,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setPickerState(() => tempIndex = index);
                      },
                      controller: FixedExtentScrollController(
                        initialItem: tempIndex,
                      ),
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: vaultOptions.length,
                        builder: (context, index) {
                          final isSelected = index == tempIndex;
                          final option = vaultOptions[index];
                          final label = option?.name ?? l10n.generalBalance;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppColors.getPrimary(context).withValues(alpha: 0.1) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    getIconData(option?.iconCode),
                                    size: isSelected ? 24 : 18,
                                    color: isSelected
                                        ? AppColors.getPrimary(context)
                                        : AppColors.getTextSecondary(context).withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: isSelected ? 22 : 18,
                                      fontWeight: isSelected
                                          ? FontWeight.w900
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.getTextPrimary(context)
                                          : AppColors.getTextSecondary(context).withValues(alpha: 0.5),
                                      letterSpacing: isSelected ? -0.5 : 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrecisionClickable(
                    onTap: () {
                      final vid = vaultOptions[tempIndex]?.id;
                      if (vid != null) {
                        onChanged([vid]);
                      } else {
                        onChanged([]);
                      }
                      Navigator.pop(context);
                    },
                    height: 56,
                    color: Colors.transparent,
                    pressedColor: AppColors.getPrimary(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                    child: Center(
                      child: Text(
                        l10n.ok.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.getPrimary(context),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              getIconData(selectedVault?.iconCode),
              size: 14,
              color: AppColors.getPrimary(context),
            ),
            const SizedBox(width: 6),
            Text(
              selectedVault?.name ?? l10n.generalBalance,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: AppColors.getTextPrimary(context),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

