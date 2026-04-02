import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/fluid_container.dart';
import '../../../shared/widgets/fluid_button.dart';
import '../../../shared/widgets/fluid_sheet.dart';
import '../vaults_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';

class GroupDetailSheet extends ConsumerWidget {
  final TransactionGroup group;

  const GroupDetailSheet({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final allTransactions = ref.watch(vaultTransactionsProvider);
    
    // Bu gruba ait olan işlemleri filtrele
    final groupTransactions = allTransactions
        .where((t) => t.groupIds.contains(group.id))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.getPrimary(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BAŞLIK VE ÖZET
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              group.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${groupTransactions.length} ${l10n.items}',
                style: TextStyle(color: activeColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),

        // LİSTE
        if (groupTransactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  children: [
                    Icon(Icons.layers_clear_rounded, size: 48, color: activeColor),
                    const SizedBox(height: 12),
                    Text(l10n.noTransactions, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: groupTransactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = groupTransactions[index];
                return FluidContainer(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 24,
                  isGlass: true,
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.01),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: tx.color.withValues(alpha: 0.12), 
                          borderRadius: BorderRadius.circular(14)
                        ),
                        child: Icon(tx.icon, color: tx.color, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            Text(
                              '₺${CurrencyUtils.formatAmount(tx.amount)}', 
                              style: TextStyle(
                                color: tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context), 
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              )
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error),
                        onPressed: () async {
                          final helper = ref.read(transactionGroupingProvider);
                          await helper.toggleVault(tx.id, group.id);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        
        const SizedBox(height: 24),
        
        // EKLE BUTONU
        FluidButton(
          onTap: () => _showAddTransactionPicker(context, ref, group.id),
          width: double.infinity,
          color: activeColor.withValues(alpha: 0.1),
          isSecondary: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: activeColor),
              const SizedBox(width: 8),
              Text(l10n.addTransaction, style: TextStyle(color: activeColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showAddTransactionPicker(BuildContext context, WidgetRef ref, String groupId) {
    FluidSheet.show(
      context: context,
      title: AppLocalizations.of(context)!.addTransaction,
      child: Consumer(
        builder: (context, ref, _) {
          final allTransactions = ref.watch(vaultTransactionsProvider);
          // Henüz BU grupta olmayanları göster
          final availableTx = allTransactions
              .where((t) => !t.groupIds.contains(groupId))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          if (availableTx.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('Eklenebilecek işlem bulunamadı.', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            itemCount: availableTx.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final tx = availableTx[index];
              return GestureDetector(
                onTap: () async {
                  final helper = ref.read(transactionGroupingProvider);
                  await helper.toggleVault(tx.id, groupId);
                  if (context.mounted) Navigator.pop(context);
                },
                child: FluidContainer(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 20,
                  isGlass: true,
                  child: Row(
                    children: [
                      Icon(tx.icon, color: tx.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('₺${CurrencyUtils.formatAmount(tx.amount)}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.add_rounded, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
