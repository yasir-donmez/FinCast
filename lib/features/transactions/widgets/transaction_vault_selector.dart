import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/database/models/vault.dart';
import '../../../shared/widgets/precision_inline_picker.dart';

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

    return PrecisionInlinePicker(
      items: vaultOptions.map((v) => v?.name ?? l10n.allLabel).toList(),
      selectedIndex: currentIndex,
      onChanged: (index) {
        final vault = vaultOptions[index];
        if (vault == null) {
          onChanged([]);
        } else {
          onChanged([vault.id]);
        }
      },
      width: 120,
    );
  }
}
