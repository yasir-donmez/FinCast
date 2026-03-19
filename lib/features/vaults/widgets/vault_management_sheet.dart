import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/providers/db_providers.dart';
import '../../../shared/widgets/neu_container.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../../l10n/app_localizations.dart';

class VaultManagementSheet extends ConsumerWidget {
  const VaultManagementSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final vaults = ref.watch(allVaultsProvider);
    final transactions = ref.watch(allTransactionsProvider);
    final ungroupedTx = transactions.where((t) => t.vaultId == null).toList();

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.visibilityManagement,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.visibilityDesc,
            style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(context)),
          ),
          const SizedBox(height: 24),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vaults.isNotEmpty) ...[
                    _buildSectionHeader(context, l10n.vaultsAndGroups),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: vaults.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final vault = vaults[index];
                        final vaultTx = transactions
                            .where((t) => t.vaultId == vault.id)
                            .toList();
                        final dominantIcon =
                            IconUtils.getDominantIconCode(
                              vaultTx
                                  .map((t) => t.iconCode ?? t.title)
                                  .toList(),
                            ) ??
                            vault.iconCode;

                        return _buildManagementItem(
                          context: context,
                          title: vault.name,
                          subtitle: vault.currency,
                          iconCode: dominantIcon,
                          value: vault.showOnDashboard,
                          onChanged: (val) async {
                            vault.showOnDashboard = val;
                            await DatabaseService.updateVault(vault);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (ungroupedTx.isNotEmpty) ...[
                    _buildSectionHeader(context, l10n.individualTransactions),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ungroupedTx.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tx = ungroupedTx[index];
                        return _buildManagementItem(
                          context: context,
                          title: tx.title,
                          subtitle: '₺${tx.amount.toStringAsFixed(0)}',
                          subtitleColor: tx.isIncome
                              ? AppColors.getIncome(context)
                              : AppColors.getExpense(context),
                          iconCode: tx.iconCode,
                          value: tx.showOnDashboard,
                          onChanged: (val) async {
                            tx.showOnDashboard = val;
                            await DatabaseService.updateTransaction(tx);
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.getTextSecondary(context),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildManagementItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    Color? subtitleColor,
    String? iconCode,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return NeuContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: AppSizes.radiusDefault,
      child: Row(
        children: [
          Icon(
            IconUtils.getIcon(iconCode ?? title),
            color: IconUtils.getColor(iconCode ?? title),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor ?? AppColors.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.getPrimary(context),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
