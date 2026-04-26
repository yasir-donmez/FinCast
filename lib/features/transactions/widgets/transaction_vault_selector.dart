import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/database/models/vault.dart';

class TransactionVaultSelector extends StatefulWidget {
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
  State<TransactionVaultSelector> createState() => _TransactionVaultSelectorState();
}

class _TransactionVaultSelectorState extends State<TransactionVaultSelector> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    final List<Vault?> vaultOptions = [null, ...widget.vaults];
    int index = vaultOptions.indexWhere(
      (v) => widget.selectedVaultIds.contains(v?.id),
    );
    if (index == -1) index = 0;
    _controller = FixedExtentScrollController(initialItem: index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vaults = widget.vaults;
    final selectedVaultIds = widget.selectedVaultIds;
    final onChanged = widget.onChanged;

    final l10n = AppLocalizations.of(context)!;
    final List<Vault?> vaultOptions = [null, ...vaults];

    // Mevcut seçimin indexini bul
    int currentIndex = vaultOptions.indexWhere(
      (v) => selectedVaultIds.contains(v?.id),
    );
    if (currentIndex == -1) currentIndex = 0;

    return SizedBox(
      height: 64, // Yükseklik artırıldı (Peek için)
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Estetik Vurgu Çizgileri (Sabit ve Kompakt Genişlik)
          Container(
            width: 120, // Her iki seçicide de aynı boyda olması için sabitlendi
            height: 34,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.getPrimary(context).withValues(alpha: 0.1), width: 0.8),
                bottom: BorderSide(color: AppColors.getPrimary(context).withValues(alpha: 0.1), width: 0.8),
              ),
            ),
          ),
          
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 32,
            physics: const FixedExtentScrollPhysics(),
            perspective: 0.006,
            diameterRatio: 1.0,
            overAndUnderCenterOpacity: 0.6, // Biraz daha belli olsunlar
            useMagnifier: true,
            magnification: 1.15,
            onSelectedItemChanged: (index) {
              HapticFeedback.selectionClick();
              final vault = vaultOptions[index];
              if (vault == null) {
                onChanged([]);
              } else {
                onChanged([vault.id]);
              }
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: vaultOptions.length,
              builder: (context, index) {
                final vault = vaultOptions[index];
                final isSelected = (vault == null && selectedVaultIds.isEmpty) ||
                    (vault != null && selectedVaultIds.contains(vault.id));
                
                return Center(
                  child: Text(
                    vault?.name ?? l10n.allLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                      color: isSelected 
                          ? AppColors.getPrimary(context) 
                          : AppColors.getTextSecondary(context).withValues(alpha: 0.8),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
