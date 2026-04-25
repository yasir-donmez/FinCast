import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/models/vault.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/providers/db_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../vaults_providers.dart';
import '../../../shared/widgets/fluid_switch.dart';
import '../../../shared/widgets/fluid_tab_selector.dart';
import '../../../shared/widgets/precision_card.dart';

enum VisibilityTab { vaults, transactions }

class VaultVisibilitySheet extends ConsumerStatefulWidget {
  const VaultVisibilitySheet({super.key});

  @override
  ConsumerState<VaultVisibilitySheet> createState() => _VaultVisibilitySheetState();
}

class _VaultVisibilitySheetState extends ConsumerState<VaultVisibilitySheet> {
  VisibilityTab _activeTab = VisibilityTab.vaults;

  void _switchTab(VisibilityTab tab) {
    if (_activeTab == tab) return;
    HapticFeedback.mediumImpact();
    setState(() => _activeTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final vaults = ref.watch(allVaultsProvider);
    final transactions = ref.watch(vaultTransactionsProvider);
    final l10n = AppLocalizations.of(context)!;
    final allTransactions = transactions.toList();
    
    final activeColor = AppColors.getPrimary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scalingFactor = (MediaQuery.of(context).size.height / 812.0).clamp(0.85, 1.0);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FluidTabSelector(
          tabs: const ['Kasalar', 'İşlemler'],
          selectedIndex: _activeTab == VisibilityTab.vaults ? 0 : 1,
          onTabChanged: (index) => _switchTab(index == 0 ? VisibilityTab.vaults : VisibilityTab.transactions),
          scalingFactor: scalingFactor,
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _activeTab == VisibilityTab.vaults 
              ? _buildVaultListView(context, vaults, activeColor, isDark, scalingFactor)
              : _buildTransactionListView(context, allTransactions, activeColor, isDark, scalingFactor, l10n),
        ),
      ],
    );
  }

  Widget _buildVaultListView(BuildContext context, List<Vault> vaults, Color activeColor, bool isDark, double scalingFactor) {
    return Column(
      key: const ValueKey('vault_list'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (vaults.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5 * scalingFactor),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8 * scalingFactor),
              physics: const BouncingScrollPhysics(),
              itemCount: vaults.length,
              separatorBuilder: (_, __) => SizedBox(height: 10 * scalingFactor),
              itemBuilder: (context, index) => _buildVaultItem(context, vaults[index], activeColor, isDark, scalingFactor),
            ),
          )
        else
          _buildEmptyState('Henüz bir kasa bulunmuyor.', Icons.account_balance_wallet_outlined, activeColor, scalingFactor),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTransactionListView(BuildContext context, List<TransactionUI> txs, Color activeColor, bool isDark, double scalingFactor, AppLocalizations l10n) {
    return Column(
      key: const ValueKey('tx_list'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (txs.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5 * scalingFactor),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8 * scalingFactor),
              physics: const BouncingScrollPhysics(),
              itemCount: txs.length,
              separatorBuilder: (_, __) => SizedBox(height: 10 * scalingFactor),
              itemBuilder: (context, index) => _buildTransactionItem(context, txs[index], activeColor, isDark, scalingFactor, l10n),
            ),
          )
        else
          _buildEmptyState('Tekil işlem bulunamadı.', Icons.receipt_long_rounded, activeColor, scalingFactor),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon, Color color, double scalingFactor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 60 * scalingFactor),
      child: Opacity(
        opacity: 0.5,
        child: Column(
          children: [
            Icon(icon, size: 48 * scalingFactor, color: color),
            SizedBox(height: 12 * scalingFactor),
            Text(message, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13 * scalingFactor)),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultItem(BuildContext context, Vault vault, Color activeColor, bool isDark, double scalingFactor) {
    return PrecisionCard(
      scalingFactor: scalingFactor,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8 * scalingFactor),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12 * scalingFactor),
            ),
            child: Icon(
              IconUtils.getIcon(vault.iconCode ?? vault.name),
              color: activeColor,
              size: 20 * scalingFactor,
            ),
          ),
          SizedBox(width: 12 * scalingFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vault.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15 * scalingFactor,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  vault.currency,
                  style: TextStyle(
                    fontSize: 10 * scalingFactor,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          FluidSwitch(
            value: vault.showOnDashboard,
            activeColor: activeColor,
            activeIcon: Icons.visibility_rounded,
            inactiveIcon: Icons.visibility_off_rounded,
            scalingFactor: 0.75 * scalingFactor,
            onChanged: (val) async {
              vault.showOnDashboard = val;
              await DatabaseService.updateVault(vault);
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionUI tx, Color activeColor, bool isDark, double scalingFactor, AppLocalizations l10n) {
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
            child: Icon(
              tx.icon,
              color: tx.color,
              size: 20 * scalingFactor,
            ),
          ),
          SizedBox(width: 12 * scalingFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.categoryId != null
                      ? "${(tx.isIncome ? l10n.income : l10n.expense)} / ${tx.name}"
                      : tx.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14 * scalingFactor,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '₺${CurrencyUtils.formatAmount(tx.amount)}',
                  style: TextStyle(
                    fontSize: 11 * scalingFactor,
                    fontWeight: FontWeight.w800,
                    color: tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context),
                  ),
                ),
              ],
            ),
          ),
          FluidSwitch(
            value: tx.showOnDashboard,
            activeColor: activeColor,
            activeIcon: Icons.visibility_rounded,
            inactiveIcon: Icons.visibility_off_rounded,
            scalingFactor: 0.75 * scalingFactor,
            onChanged: (val) async {
              if (tx.dbId == null) return;
              final record = await DatabaseService.getTransaction(tx.dbId!);
              if (record != null) {
                record.showOnDashboard = val;
                await DatabaseService.updateTransaction(record);
                HapticFeedback.lightImpact();
              }
            },
          ),
        ],
      ),
    );
  }
}
