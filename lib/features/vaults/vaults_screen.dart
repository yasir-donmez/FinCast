import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../core/database/models/vault.dart';
import '../../core/utils/currency_utils.dart';
import 'vaults_providers.dart';
import 'widgets/transaction_card.dart';
import 'widgets/group_card.dart';
import 'widgets/group_detail_sheet.dart';
import '../transactions/add_transaction_sheet.dart'; 
import 'widgets/vault_management_sheet.dart';

class VaultsScreen extends ConsumerStatefulWidget {
  const VaultsScreen({super.key});

  @override
  ConsumerState<VaultsScreen> createState() => _VaultsScreenState();
}

class _VaultsScreenState extends ConsumerState<VaultsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allTransactions = ref.watch(mockTransactionsProvider);
    final groups = ref.watch(transactionGroupsProvider);
    final filter = ref.watch(transactionFilterProvider);
    final isEditMode = ref.watch(editModeProvider);
    final selectedVaultId = ref.watch(selectedVaultProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    final vaultTransactions = selectedVaultId == null
        ? allTransactions
        : allTransactions.where((t) => t.groupId == selectedVaultId).toList();

    var filteredTransactions = vaultTransactions.where((t) {
      if (filter == TransactionFilter.income) return t.isIncome;
      if (filter == TransactionFilter.expense) return !t.isIncome;
      return true;
    }).toList();

    if (selectedPeriod != null) {
      filteredTransactions = filteredTransactions.where((t) => t.periodType == selectedPeriod).toList();
    }

    final totalIncome = vaultTransactions.where((t) => t.isIncome).fold<double>(0, (sum, t) => sum + t.monthlyEquivalent);
    final totalExpense = vaultTransactions.where((t) => !t.isIncome).fold<double>(0, (sum, t) => sum + t.monthlyEquivalent);

    // Yeni İstatistikler
    final netBalance = totalIncome - totalExpense;
    
    // Min/Max/Avg Net Balance
    final minIncome = vaultTransactions.where((t) => t.isIncome).fold<double>(0, (sum, t) => sum + t.minMonthlyEquivalent);
    final maxIncome = vaultTransactions.where((t) => t.isIncome).fold<double>(0, (sum, t) => sum + t.maxMonthlyEquivalent);
    // avgIncome removed as it's not used

    final minExpense = vaultTransactions.where((t) => !t.isIncome).fold<double>(0, (sum, t) => sum + t.minMonthlyEquivalent);
    final maxExpense = vaultTransactions.where((t) => !t.isIncome).fold<double>(0, (sum, t) => sum + t.maxMonthlyEquivalent);
    // avgExpense removed as it's not used

    final minNet = minIncome - maxExpense;
    final maxNet = maxIncome - minExpense;
    // avgNet removed as it's not used

    final bool hasFlexibleTx = vaultTransactions.any((t) => t.minAmount != null || t.maxAmount != null);

    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final surfaceColor = AppColors.getSurface(context);
    final darkShadowColor = AppColors.getDarkShadow(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.paddingMedium),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.vaults,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(editModeProvider.notifier).state = !isEditMode;
                  if (!isEditMode) HapticFeedback.mediumImpact();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isEditMode ? AppColors.primary.withValues(alpha: 0.15) : surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isEditMode ? AppColors.primary.withValues(alpha: 0.4) : darkShadowColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isEditMode ? l10n.done : l10n.edit,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isEditMode ? AppColors.primary : textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showVaultManagementSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: darkShadowColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.account_balance_wallet_rounded, size: 18, color: textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 135,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              proxyDecorator: (child, index, animation) => Material(color: Colors.transparent, child: child),
              onReorder: (oldIndex, newIndex) {
                if (oldIndex == 0 || newIndex == 0) return;
                final realOld = oldIndex - 1;
                var realNew = newIndex - 1;
                if (realNew > realOld) realNew--;
                final currentGroups = ref.read(transactionGroupsProvider);
                final updatedIds = currentGroups.map((g) => g.id).toList();
                final movedId = updatedIds.removeAt(realOld);
                updatedIds.insert(realNew, movedId);
                ref.read(transactionGroupsNotifierProvider).reorderGroups(updatedIds);
                HapticFeedback.mediumImpact();
              },
              itemCount: groups.length + 1 + (isEditMode ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = selectedVaultId == null;
                  return Container(
                    key: const ValueKey('ana_kasa'),
                    margin: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => ref.read(selectedVaultProvider.notifier).state = null,
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : surfaceColor,
                          borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : darkShadowColor.withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1)] : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.dashboard_rounded, color: isSelected ? AppColors.primary : textSecondary, size: 24),
                            const SizedBox(height: 8),
                            Text(
                              l10n.mainVault,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                                color: isSelected ? AppColors.primary : textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                if (isEditMode && index == groups.length + 1) {
                  return Container(
                    key: const ValueKey('add_vault_button'),
                    margin: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () async {
                        final vault = Vault()
                          ..name = 'Kasa ${groups.length + 1}'
                          ..currency = 'TRY'
                          ..balance = 0
                          ..showOnDashboard = true
                          ..dashboardOrder = groups.length;
                        await DatabaseService.addVault(vault);
                        HapticFeedback.heavyImpact();
                      },
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
                            const SizedBox(height: 8),
                            Text(l10n.newVault, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                final group = groups[index - 1];
                final isSelected = selectedVaultId == group.id;
                return Padding(
                  key: ValueKey(group.id),
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: isEditMode
                        ? () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => GroupDetailSheet(group: group))
                        : () => ref.read(selectedVaultProvider.notifier).state = group.id,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 100,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null),
                      child: Opacity(opacity: isSelected || isEditMode ? 1.0 : 0.7, child: _buildGroupItem(context, ref, group, isEditMode)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          // Genişletilmiş İstatistik Çipleri (Kaydırılabilir)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _SummaryChip(
                  label: l10n.monthlyIncome,
                  amount: '₺${CurrencyUtils.formatFullAmount(totalIncome)}',
                  color: AppColors.getIncome(context),
                ),
                const SizedBox(width: 10),
                _SummaryChip(
                  label: l10n.monthlyExpense,
                  amount: '₺${CurrencyUtils.formatFullAmount(totalExpense)}',
                  color: AppColors.getExpense(context),
                ),
                const SizedBox(width: 10),
                _SummaryChip(
                  label: l10n.netBalance,
                  amount: '₺${CurrencyUtils.formatFullAmount(netBalance)}',
                  color: AppColors.getPrimary(context),
                ),
                if (hasFlexibleTx) ...[
                  const SizedBox(width: 10),
                  _SummaryChip(
                    label: l10n.worstCase,
                    amount: '₺${CurrencyUtils.formatFullAmount(minNet)}',
                    color: AppColors.getWarning(context),
                  ),
                  const SizedBox(width: 10),
                  _SummaryChip(
                    label: l10n.bestCase,
                    amount: '₺${CurrencyUtils.formatFullAmount(maxNet)}',
                    color: AppColors.getInfo(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _FilterChip(label: l10n.all, isActive: filter == TransactionFilter.all, onTap: () => ref.read(transactionFilterProvider.notifier).state = TransactionFilter.all),
              const SizedBox(width: 8),
              _FilterChip(label: l10n.income, isActive: filter == TransactionFilter.income, onTap: () => ref.read(transactionFilterProvider.notifier).state = TransactionFilter.income, activeColor: AppColors.getIncome(context)),
              const SizedBox(width: 8),
              _FilterChip(label: l10n.expense, isActive: filter == TransactionFilter.expense, onTap: () => ref.read(transactionFilterProvider.notifier).state = TransactionFilter.expense, activeColor: AppColors.error),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _FilterChip(label: l10n.allTime, isActive: selectedPeriod == null, onTap: () => ref.read(selectedPeriodProvider.notifier).state = null),
                const SizedBox(width: 8),
                _FilterChip(label: l10n.oneTime, isActive: selectedPeriod == 0, onTap: () => ref.read(selectedPeriodProvider.notifier).state = 0),
                const SizedBox(width: 8),
                _FilterChip(label: l10n.weekly, isActive: selectedPeriod == 1, onTap: () => ref.read(selectedPeriodProvider.notifier).state = 1),
                const SizedBox(width: 8),
                _FilterChip(label: l10n.every2Weeks, isActive: selectedPeriod == 4, onTap: () => ref.read(selectedPeriodProvider.notifier).state = 4),
                const SizedBox(width: 8),
                _FilterChip(label: l10n.every3Weeks, isActive: selectedPeriod == 5, onTap: () => ref.read(selectedPeriodProvider.notifier).state = 5),
                const SizedBox(width: 8),
                _FilterChip(label: l10n.monthly, isActive: selectedPeriod == 2, onTap: () => ref.read(selectedPeriodProvider.notifier).state = 2),
                const SizedBox(width: 8),
                _FilterChip(label: l10n.every3Months, isActive: selectedPeriod == 6, onTap: () => ref.read(selectedPeriodProvider.notifier).state = 6),
                const SizedBox(width: 8),
                _FilterChip(label: l10n.every6Months, isActive: selectedPeriod == 7, onTap: () => ref.read(selectedPeriodProvider.notifier).state = 7),
                const SizedBox(width: 8),
                _FilterChip(label: l10n.yearly, isActive: selectedPeriod == 3, onTap: () => ref.read(selectedPeriodProvider.notifier).state = 3),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 60, color: textSecondary.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(l10n.noTransactions, style: TextStyle(color: textSecondary, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      _buildPeriodSection(
                        selectedPeriod == null ? l10n.allTime : selectedPeriod == 0 ? l10n.oneTime : selectedPeriod == 1 ? l10n.weekly : selectedPeriod == 4 ? l10n.every2Weeks : selectedPeriod == 5 ? l10n.every3Weeks : selectedPeriod == 2 ? l10n.monthly : selectedPeriod == 6 ? l10n.every3Months : selectedPeriod == 7 ? l10n.every6Months : l10n.yearly,
                        filteredTransactions, context, ref,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSection(String title, List<MockTransaction> txList, BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.getTextPrimary(context), letterSpacing: 0.5)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.getTextSecondary(context).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text('${txList.length}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.getTextSecondary(context))),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85),
          itemCount: txList.length,
          itemBuilder: (context, index) => TransactionCard(
            transaction: txList[index],
            onTap: () => _showTransactionDetail(context, txList[index]),
            onLongPress: () => _handleTransactionLongPress(context, ref, txList[index]),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showTransactionDetail(BuildContext context, MockTransaction tx) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLarge)),
        title: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: tx.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Icon(tx.icon, color: tx.color)),
            const SizedBox(width: 12),
            Expanded(child: Text(tx.name, style: TextStyle(color: AppColors.getTextPrimary(context), fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.amount}: ₺${tx.amount.toStringAsFixed(1).replaceAll(RegExp(r"\.0$"), "")}', style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 18, fontWeight: FontWeight.bold)),
            if (tx.minAmount != null && tx.maxAmount != null)
              Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('Limit / Hedef: ₺${tx.minAmount!.toStringAsFixed(1).replaceAll(RegExp(r"\.0$"), "")} ~ ₺${tx.maxAmount!.toStringAsFixed(1).replaceAll(RegExp(r"\.0$"), "")}', style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 14))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.close, style: TextStyle(color: AppColors.getTextPrimary(context)))),
        ],
      ),
    );
  }

  void _handleTransactionLongPress(BuildContext context, WidgetRef ref, MockTransaction tx) {
    if (tx.dbId == null) return;
    HapticFeedback.heavyImpact();

    showTransactionActionMenu(
      context,
      name: tx.name,
      isInVault: tx.groupId != null,
      onEdit: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddTransactionSheet(
            initialId: tx.dbId,
            initialName: tx.name,
            initialAmount: tx.amount,
            initialMinAmount: tx.minAmount,
            initialMaxAmount: tx.maxAmount,
            initialIsIncome: tx.isIncome,
            initialVaultId: tx.groupId != null ? int.tryParse(tx.groupId!.replaceFirst('v_', '')) : null,
            initialCategoryId: tx.categoryId,
          ),
        );
      },
      onDelete: () async {
        final l10n = AppLocalizations.of(context)!;
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.getSurface(context),
            title: Text(l10n.permanentDelete, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(l10n.permanentDeleteDesc),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel, style: TextStyle(color: AppColors.getTextSecondary(context)))),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.ok, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))),
            ],
          ),
        );

        if (confirm == true) {
          await DatabaseService.deleteTransaction(tx.dbId!);
          HapticFeedback.mediumImpact();
        }
      },
    );
  }

  Widget _buildGroupItem(BuildContext context, WidgetRef ref, TransactionGroup group, bool isEditMode) {
    final allTx = ref.watch(mockTransactionsProvider);
    final groupTx = allTx.where((t) => group.transactionIds.contains(t.id)).toList();
    return GroupCard(
      group: group,
      transactions: groupTx,
      isEditMode: isEditMode,
      onTap: null,
      onDelete: () async {
        for (final txId in group.transactionIds) {
          await ref.read(transactionGroupingProvider).setGroupId(txId, null);
        }
        await ref.read(transactionGroupsNotifierProvider).deleteGroup(group.id);
        HapticFeedback.lightImpact();
      },
    );
  }

  void _showVaultManagementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VaultManagementSheet(),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _SummaryChip({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getDarkShadow(context).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(amount, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? activeColor;

  const _FilterChip({required this.label, required this.isActive, required this.onTap, this.activeColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? (activeColor ?? AppColors.primary).withValues(alpha: 0.15) : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? (activeColor ?? AppColors.primary).withValues(alpha: 0.4) : AppColors.getDarkShadow(context).withValues(alpha: 0.3)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? (activeColor ?? AppColors.primary) : AppColors.getTextSecondary(context),
            ),
          ),
        ),
      ),
    );
  }
}
