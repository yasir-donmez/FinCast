import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/neu_container.dart';
import '../vaults_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// Gruba tıklayınca açılan bottom sheet
/// İçindeki işlemleri listeler + isim düzenleme + işlem çıkarma
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
    final allTransactions = ref.watch(mockTransactionsProvider);
    final group = ref
        .watch(transactionGroupsProvider)
        .firstWhere((g) => g.id == widget.group.id, orElse: () => widget.group);

    final groupTransactions = allTransactions
        .where((t) => group.transactionIds.contains(t.id))
        .toList();

    // Boş kasalar da (özellikle yeni oluşturulmuşlar) artık yönetilebilir olmalı
    // Bu yüzden < 2 ise kapatma şartını kaldırıyoruz.

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLarge),
        ),
      ),
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Başlık — grup adı (tıkla → düzenle)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _isEditingName
                      ? TextField(
                          controller: _nameController,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(context),
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: l10n.groupNameHint,
                            hintStyle: TextStyle(
                              color: AppColors.getTextSecondary(context),
                            ),
                          ),
                          onSubmitted: (value) async {
                            if (value.trim().isNotEmpty) {
                              await ref
                                  .read(transactionGroupsNotifierProvider)
                                  .renameGroup(widget.group.id, value.trim());
                            }
                            setState(() => _isEditingName = false);
                          },
                        )
                      : GestureDetector(
                          onTap: () => setState(() => _isEditingName = true),
                          child: Row(
                            children: [
                              Text(
                                group.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: AppColors.getTextSecondary(context).withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                        ),
                ),
                // Kapat butonu
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.getDarkShadow(context),
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                        BoxShadow(
                          color: AppColors.getLightShadow(context),
                          offset: Offset(-2, -2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
            ),
            child: Text(
              l10n.transactionCount(groupTransactions.length),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextSecondary(context),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // İşlem listesi
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                ...groupTransactions.map((tx) {
                  String? periodLabel;
                  switch (tx.periodType) {
                    case 1:
                      periodLabel = 'Haftalık';
                      break;
                    case 4:
                      periodLabel = '2 Haftalık';
                      break;
                    case 5:
                      periodLabel = '3 Haftalık';
                      break;
                    case 2:
                      periodLabel = 'Aylık';
                      break;
                    case 6:
                      periodLabel = '3 Aylık';
                      break;
                    case 7:
                      periodLabel = '6 Aylık';
                      break;
                    case 3:
                      periodLabel = 'Yıllık';
                      break;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingMedium,
                      vertical: 6,
                    ),
                    child: NeuContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      borderRadius: AppSizes.radiusDefault,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: tx.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: tx.color.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: Icon(tx.icon, color: tx.color, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                                if (periodLabel != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tx.isIncome
                                          ? AppColors.getIncome(context).withValues(alpha: 0.15)
                                          : AppColors.getExpense(context).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: tx.isIncome
                                            ? AppColors.getIncome(context).withValues(alpha: 0.3)
                                            : AppColors.getExpense(context).withValues(alpha: 0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.cached_rounded,
                                          size: 10,
                                          color: tx.isIncome
                                              ? AppColors.getIncome(context)
                                              : AppColors.getExpense(context),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          periodLabel,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: tx.isIncome
                                                ? AppColors.getIncome(context)
                                                : AppColors.getExpense(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '₺${tx.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: tx.isIncome
                                      ? AppColors.getIncome(context)
                                      : AppColors.getExpense(context),
                                ),
                              ),
                              if (tx.minAmount != null &&
                                  tx.maxAmount != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_downward_rounded,
                                      size: 10,
                                      color: AppColors.getExpense(context),
                                    ),
                                    Text(
                                      tx.minAmount!.toStringAsFixed(0),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.getExpense(context),
                                      ),
                                    ),
                                    Text(
                                      ' ~ ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.getTextSecondary(context)
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 10,
                                      color: AppColors.getIncome(context),
                                    ),
                                    Text(
                                      tx.maxAmount!.toStringAsFixed(0),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.getIncome(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Gruptan çıkar butonu
                          GestureDetector(
                            onTap: () async {
                              await ref
                                  .read(transactionGroupsNotifierProvider)
                                  .removeFromGroup(widget.group.id, tx.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.getInnerSurface(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 18,
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                // İşlem Ekle Butonu
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMedium,
                    vertical: 12,
                  ),
                  child: GestureDetector(
                    onTap: () => _showAddTransactionPicker(context, group),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusDefault,
                        ),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.addTransaction,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showAddTransactionPicker(BuildContext context, TransactionGroup group) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) {
        final allTransactions = ref.watch(mockTransactionsProvider);
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
