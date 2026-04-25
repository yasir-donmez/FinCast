import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/models/vault.dart';
import '../../../core/providers/db_providers.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../shared/widgets/fluid_switch.dart';
import '../../../shared/widgets/fluid_tab_selector.dart';
import '../../../shared/widgets/precision_card.dart';
import '../../../shared/widgets/precision_input.dart';
import '../../../shared/widgets/precision_icon_button.dart';
import '../../../shared/widgets/fluid_animated_icon.dart';
import '../../../shared/widgets/precision_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../vaults_providers.dart';

enum VaultDetailTab { transactions, manage }

class VaultDetailSheet extends ConsumerStatefulWidget {
  final String vaultId;
  const VaultDetailSheet({super.key, required this.vaultId});

  @override
  ConsumerState<VaultDetailSheet> createState() => _VaultDetailSheetState();
}

class _VaultDetailSheetState extends ConsumerState<VaultDetailSheet> with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  bool _isEditingName = false;
  VaultDetailTab _activeTab = VaultDetailTab.transactions;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _switchTab(VaultDetailTab tab) {
    if (_activeTab == tab) return;
    HapticFeedback.mediumImpact();
    setState(() => _activeTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final allVaults = ref.watch(allVaultsProvider);
    final vaultDbId = int.tryParse(widget.vaultId.replaceFirst('v_', ''));
    
    final vault = allVaults.where((v) => v.id == vaultDbId).firstOrNull;
    if (vault == null) return const SizedBox.shrink();

    if (!_isEditingName && _nameController.text != vault.name) {
      _nameController.text = vault.name;
    }

    final allTransactions = ref.watch(vaultTransactionsProvider);
    final vaultTransactions = allTransactions.where((t) => t.groupIds.contains(widget.vaultId)).toList();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.getPrimary(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final scalingFactor = (screenHeight / 812.0).clamp(0.85, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FluidTabSelector(
          tabs: const ['İşlemler', 'Yönet'],
          selectedIndex: _activeTab == VaultDetailTab.transactions ? 0 : 1,
          onTabChanged: (index) => _switchTab(index == 0 ? VaultDetailTab.transactions : VaultDetailTab.manage),
          scalingFactor: scalingFactor,
        ),
        SizedBox(height: 12 * scalingFactor),
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _activeTab == VaultDetailTab.transactions
              ? _buildMainView(context, vault, vaultTransactions, activeColor, isDark)
              : _buildSelectionView(context, allTransactions, vaultTransactions, activeColor, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildMainView(BuildContext context, Vault vault, List<TransactionUI> vaultTransactions, Color activeColor, bool isDark) {
    final screenHeight = MediaQuery.of(context).size.height;
    final scalingFactor = (screenHeight / 812.0).clamp(0.85, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        key: const ValueKey('main_view'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isEditingName
                          ? PrecisionInput(
                              key: const ValueKey('editing_input'),
                              controller: _nameController,
                              hintText: 'Kasa Adı',
                              icon: IconUtils.getIcon(vault.iconCode ?? vault.name),
                              autofocus: true,
                              scalingFactor: scalingFactor,
                              onSubmitted: () async {
                                if (_nameController.text.trim().isNotEmpty) {
                                  vault.name = _nameController.text.trim();
                                  await DatabaseService.updateVault(vault);
                                }
                                setState(() => _isEditingName = false);
                              },
                            )
                          : PrecisionCard(
                              key: const ValueKey('view_name_card'),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0 * scalingFactor),
                              backgroundColor: Colors.transparent,
                              borderColor: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _nameController.text = vault.name;
                                  setState(() => _isEditingName = true);
                                  HapticFeedback.lightImpact();
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      IconUtils.getIcon(vault.iconCode ?? vault.name),
                                      color: activeColor.withValues(alpha: 0.4),
                                      size: 22 * scalingFactor,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        vault.name,
                                        style: TextStyle(
                                          fontSize: 17 * scalingFactor, 
                                          fontWeight: FontWeight.w800, 
                                          letterSpacing: -0.5,
                                          color: AppColors.getTextPrimary(context),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    PrecisionIconButton(
                      onTap: () async {
                        if (_isEditingName) {
                          if (_nameController.text.trim().isNotEmpty) {
                            vault.name = _nameController.text.trim();
                            await DatabaseService.updateVault(vault);
                          }
                          setState(() => _isEditingName = false);
                        } else {
                          _nameController.text = vault.name;
                          setState(() => _isEditingName = true);
                        }
                        HapticFeedback.lightImpact();
                      },
                      color: _isEditingName ? Colors.green : Colors.grey,
                      backgroundColor: (_isEditingName ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                      padding: 12,
                      borderRadius: 14,
                      child: FluidAnimatedIcon(
                        activeIcon: Icons.check_rounded,
                        inactiveIcon: Icons.edit_rounded,
                        isActive: _isEditingName,
                        color: _isEditingName ? Colors.green : Colors.grey,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    PrecisionIconButton(
                      icon: Icons.delete_sweep_rounded,
                      onTap: () => _confirmDeleteVault(context, vault),
                      color: AppColors.error,
                      size: 22,
                      padding: 12,
                      borderRadius: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Görünürlük ayarı merkezi yönetime alındığı için buradan kaldırıldı.
          const SizedBox(height: 24),
          Text(
            'İşlemler',
            style: TextStyle(fontSize: 14 * scalingFactor, fontWeight: FontWeight.w900, color: Colors.grey.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 12),
          if (vaultTransactions.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35 * scalingFactor),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 4 * scalingFactor),
                itemCount: vaultTransactions.length,
                separatorBuilder: (_, __) => SizedBox(height: 10 * scalingFactor),
                itemBuilder: (context, index) => _buildTransactionItem(context, vaultTransactions[index], scalingFactor, isDark),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 40 * scalingFactor),
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 40 * scalingFactor),
                    SizedBox(height: 8 * scalingFactor),
                    Text('Bu kasada işlem bulunmuyor.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13 * scalingFactor)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSelectionView(BuildContext context, List<TransactionUI> allTransactions, List<TransactionUI> vaultTransactions, Color activeColor, bool isDark) {
    final scalingFactor = (MediaQuery.of(context).size.height / 812.0).clamp(0.85, 1.0);
    final standaloneTransactions = allTransactions.where((t) => t.groupIds.isEmpty || t.groupIds.contains(widget.vaultId)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        key: const ValueKey('selection_view'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kasadaki İşlemleri Yönet',
            style: TextStyle(fontSize: 18 * scalingFactor, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu kasaya dahil etmek istediğiniz işlemleri seçin.',
            style: TextStyle(fontSize: 12 * scalingFactor, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45 * scalingFactor),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: 8 * scalingFactor),
              itemCount: standaloneTransactions.length,
              separatorBuilder: (_, __) => SizedBox(height: 10 * scalingFactor),
              itemBuilder: (context, index) {
                final tx = standaloneTransactions[index];
                final isSelected = vaultTransactions.any((vtx) => vtx.id == tx.id);
                return PrecisionCard(
                  scalingFactor: scalingFactor,
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8 * scalingFactor),
                        decoration: BoxDecoration(
                          color: tx.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12 * scalingFactor),
                        ),
                        child: Icon(tx.icon, color: tx.color, size: 20 * scalingFactor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(tx.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14 * scalingFactor)),
                      ),
                      FluidSwitch(
                        value: isSelected,
                        activeColor: activeColor,
                        activeIcon: Icons.check_rounded,
                        inactiveIcon: Icons.add_rounded,
                        scalingFactor: 0.75 * scalingFactor,
                        onChanged: (val) async {
                          if (tx.dbId == null) return;
                          final record = await DatabaseService.getTransaction(tx.dbId!);
                          if (record != null) {
                            final vaultDbId = int.tryParse(widget.vaultId.replaceFirst('v_', ''));
                            if (vaultDbId == null) return;
                            
                            final currentVaults = List<int>.from(record.vaultIds);
                            if (isSelected) {
                              currentVaults.remove(vaultDbId);
                            } else {
                              currentVaults.add(vaultDbId);
                            }
                            record.vaultIds = currentVaults;
                            await DatabaseService.updateTransaction(record);
                            HapticFeedback.selectionClick();
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionUI tx, double sf, bool isDark) {
    return PrecisionCard(
      scalingFactor: sf,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8 * sf),
            decoration: BoxDecoration(
              color: tx.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12 * sf),
            ),
            child: Icon(tx.icon, color: tx.color, size: 20 * sf),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14 * sf, letterSpacing: -0.5)),
                Text(
                  '${tx.currency ?? "₺"}${CurrencyUtils.formatAmount(tx.amount)}',
                  style: TextStyle(
                    fontSize: 12 * sf,
                    fontWeight: FontWeight.w900,
                    color: tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteVault(BuildContext context, Vault vault) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showPrecisionDialog<bool>(
      context: context,
      accentColor: AppColors.error,
      title: 'Kasayı Sil',
      content: '"${vault.name}" kasasını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
      actions: [
        PrecisionDialogAction(
          label: l10n.cancel, 
          onTap: () => Navigator.pop(context, false), 
          isPrimary: false,
        ),
        PrecisionDialogAction(
          label: l10n.ok, 
          onTap: () => Navigator.pop(context, true), 
          isPrimary: true,
        ),
      ],
    );

    if (confirm == true) {
      await DatabaseService.deleteVault(vault.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}
