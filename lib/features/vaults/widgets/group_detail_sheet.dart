import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/fluid_container.dart';
import '../../../shared/widgets/fluid_button.dart';
import '../../../shared/widgets/fluid_sheet.dart';
import '../vaults_providers.dart';
import '../../../../l10n/app_localizations.dart';

class GroupDetailSheet extends ConsumerStatefulWidget {
  final TransactionGroup group;

  const GroupDetailSheet({super.key, required this.group});

  @override
  ConsumerState<GroupDetailSheet> createState() => _GroupDetailSheetState();
}

class _GroupDetailSheetState extends ConsumerState<GroupDetailSheet> {
  late TextEditingController _nameController;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allTransactions = ref.watch(vaultTransactionsProvider);
    final group = ref
        .watch(transactionGroupsProvider)
        .firstWhere((g) => g.id == widget.group.id, orElse: () => widget.group);

    final groupTransactions = allTransactions
        .where((t) => group.transactionIds.contains(t.id))
        .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // İsim Düzenleme Alanı (Kompakt)
        _isEditingName
            ? TextField(
                controller: _nameController,
                autofocus: true,
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.w900, 
                  color: AppColors.getTextPrimary(context),
                  letterSpacing: -0.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Grup Adı',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_rounded, color: Colors.green),
                    onPressed: () async {
                      if (_nameController.text.trim().isNotEmpty) {
                        await ref.read(transactionGroupsNotifierProvider).renameGroup(widget.group.id, _nameController.text.trim());
                      }
                      setState(() => _isEditingName = false);
                    },
                  ),
                ),
                onSubmitted: (value) async {
                  if (value.trim().isNotEmpty) {
                    await ref.read(transactionGroupsNotifierProvider).renameGroup(widget.group.id, value.trim());
                  }
                  setState(() => _isEditingName = false);
                },
              )
            : GestureDetector(
                onTap: () => setState(() => _isEditingName = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.getPrimary(context).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        group.name, 
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w800, 
                          color: AppColors.getTextPrimary(context),
                        )
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.edit_rounded, size: 14, color: AppColors.getPrimary(context).withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
        
        const SizedBox(height: 24),

        if (groupTransactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.layers_clear_rounded, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Bu grupta henüz işlem yok.',
                    style: TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            itemCount: groupTransactions.length,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final tx = groupTransactions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FluidContainer(
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
                            Text(
                              tx.name, 
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)
                            ),
                            Text(
                              '₺${tx.amount.toStringAsFixed(0)}', 
                              style: TextStyle(
                                color: tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context), 
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              )
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ref.read(transactionGroupsNotifierProvider).removeFromGroup(widget.group.id, tx.id),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        
        const SizedBox(height: 24),
        
        FluidButton(
          onTap: () => _showAddTransactionPicker(context, group),
          width: double.infinity,
          color: AppColors.getPrimary(context).withValues(alpha: 0.1),
          isSecondary: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded, color: AppColors.getPrimary(context), size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.addTransaction, 
                style: TextStyle(
                  color: AppColors.getPrimary(context), 
                  fontWeight: FontWeight.w900,
                )
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddTransactionPicker(BuildContext context, TransactionGroup group) {
    final l10n = AppLocalizations.of(context)!;
    
    FluidSheet.show(
      context: context,
      title: l10n.addTransaction,
      child: Consumer(
        builder: (context, ref, _) {
          final allTransactions = ref.watch(vaultTransactionsProvider);
          final availableTx =
              allTransactions.where((t) => t.groupId == null).toList()
                ..sort((a, b) => b.date.compareTo(a.date));

          if (availableTx.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.getPrimary(context).withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noRemainingTransactions,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            itemCount: availableTx.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = availableTx[index];
              return FluidContainer(
                padding: const EdgeInsets.all(8),
                borderRadius: 20,
                isGlass: true,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tx.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tx.icon, color: tx.color, size: 20),
                  ),
                  title: Text(tx.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('₺${tx.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.add_rounded, color: Colors.grey),
                  onTap: () async {
                    await ref
                        .read(transactionGroupsNotifierProvider)
                        .addToGroup(group.id, tx.id);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
