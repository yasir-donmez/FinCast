import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/fluid_container.dart';
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _isEditingName
                      ? TextField(
                          controller: _nameController,
                          autofocus: true,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.getTextPrimary(context)),
                          decoration: const InputDecoration(border: InputBorder.none),
                          onSubmitted: (value) async {
                            if (value.trim().isNotEmpty) {
                              await ref.read(transactionGroupsNotifierProvider).renameGroup(widget.group.id, value.trim());
                            }
                            setState(() => _isEditingName = false);
                          },
                        )
                      : GestureDetector(
                          onTap: () => setState(() => _isEditingName = true),
                          child: Row(
                            children: [
                              Text(group.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.getTextPrimary(context))),
                              const SizedBox(width: 8),
                              Icon(Icons.edit_rounded, size: 18, color: Colors.grey.withValues(alpha: 0.5)),
                            ],
                          ),
                        ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: FluidContainer(padding: const EdgeInsets.all(8), borderRadius: 12, isGlass: true, child: const Icon(Icons.close_rounded, size: 20, color: Colors.grey)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: groupTransactions.length,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemBuilder: (context, index) {
                final tx = groupTransactions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FluidContainer(
                    padding: const EdgeInsets.all(12),
                    borderRadius: 20,
                    isGlass: true,
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: tx.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(tx.icon, color: tx.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tx.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('₺${tx.amount.toStringAsFixed(0)}', style: TextStyle(color: tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context), fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => ref.read(transactionGroupsNotifierProvider).removeFromGroup(widget.group.id, tx.id),
                          child: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error, size: 20),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: GestureDetector(
              onTap: () => _showAddTransactionPicker(context, group),
              child: FluidContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 20,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(l10n.addTransaction, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionPicker(BuildContext context, TransactionGroup group) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) {
        final allTransactions = ref.watch(vaultTransactionsProvider);
        final availableTx =
            allTransactions.where((t) => t.groupId == null).toList()
              ..sort((a, b) => b.date.compareTo(a.date));

        return AlertDialog(
          backgroundColor: AppColors.getSurface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          ),
          title: Text(
            l10n.addTransaction,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: availableTx.isEmpty
              ? Text(l10n.noRemainingTransactions)
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableTx.length,
                    itemBuilder: (context, index) {
                      final tx = availableTx[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(tx.icon, color: tx.color),
                        title: Text(tx.name),
                        subtitle: Text('₺${tx.amount.toStringAsFixed(0)}'),
                        onTap: () async {
                          await ref
                              .read(transactionGroupsNotifierProvider)
                              .addToGroup(group.id, tx.id);
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }
}
