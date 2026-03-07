import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/providers/db_providers.dart';
import '../../../shared/widgets/neu_container.dart';

class VaultManagementSheet extends ConsumerWidget {
  const VaultManagementSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaults = ref.watch(allVaultsProvider);
    final transactions = ref.watch(allTransactionsProvider);
    final ungroupedTx = transactions.where((t) => t.vaultId == null).toList();

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Görünürlük Yönetimi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ana sayfada hangi grup veya işlemlerin görüneceğini seçin.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vaults.isNotEmpty) ...[
                    _buildSectionHeader('Kasalar & Gruplar'),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: vaults.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final vault = vaults[index];
                        return _buildManagementItem(
                          title: vault.name,
                          subtitle: '${vault.currency}',
                          iconCode: vault.iconCode,
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
                    _buildSectionHeader('Tekil İşlemler'),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ungroupedTx.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tx = ungroupedTx[index];
                        return _buildManagementItem(
                          title: tx.title,
                          subtitle: '₺${tx.amount.toStringAsFixed(0)}',
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildManagementItem({
    required String title,
    required String subtitle,
    String? iconCode,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return NeuContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: AppSizes.radiusDefault,
      child: Row(
        children: [
          Icon(_getIconData(iconCode ?? ''), color: _getColorForTitle(title)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String code) {
    switch (code) {
      case 'account_balance_wallet_rounded':
        return Icons.account_balance_wallet_rounded;
      case 'attach_money_rounded':
        return Icons.attach_money_rounded;
      case 'diamond_rounded':
        return Icons.diamond_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  Color _getColorForTitle(String name) {
    final n = name.toLowerCase();
    if (n.contains('maaş')) return AppColors.primary;
    if (n.contains('dolar')) return Colors.greenAccent;
    if (n.contains('yastık') || n.contains('altın')) {
      return Colors.amberAccent;
    }
    return AppColors.secondary;
  }
}
