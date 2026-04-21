import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/database/models/vault.dart';

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

    return Column(
      children: [
        const SizedBox(height: AppSizes.paddingMedium),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.vaultOrGroup,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            GestureDetector(
              onTap: () {
                int tempIndex = currentIndex;
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (pickerContext) {
                    return StatefulBuilder(
                      builder: (context, setPickerState) {
                        return Container(
                          height: 300,
                          decoration: BoxDecoration(
                            color: AppColors.getBackground(context),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppSizes.radiusLarge),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(pickerContext),
                                      child: Text(
                                        l10n.cancel,
                                        style: TextStyle(
                                          color: AppColors.getError(context),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      l10n.selectVault,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.getTextPrimary(context),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        final vid = vaultOptions[tempIndex]?.id;
                                        if (vid != null) {
                                          onChanged([vid]);
                                        } else {
                                          onChanged([]);
                                        }
                                        Navigator.pop(pickerContext);
                                      },
                                      child: const Text(
                                        "OK",
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListWheelScrollView.useDelegate(
                                  itemExtent: 40,
                                  perspective: 0.005,
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

                                      return Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              getIconData(option?.iconCode),
                                              size: isSelected ? 24 : 18,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.getTextSecondary(context),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              label,
                                              style: TextStyle(
                                                fontSize: isSelected ? 24 : 18,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : AppColors.getTextSecondary(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getBackground(context),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  border: Border.all(
                    color: AppColors.getSurface(context),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      getIconData(selectedVault?.iconCode),
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedVault?.name ?? l10n.generalBalance,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
