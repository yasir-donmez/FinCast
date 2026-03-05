import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_constants.dart';
import '../../core/database/database_service.dart';
import 'vaults_providers.dart';
import 'widgets/transaction_card.dart';
import 'widgets/group_card.dart';
import 'widgets/group_detail_sheet.dart';
import '../transactions/add_transaction_sheet.dart';

/// Kasalar — İşlem Yönetim Merkezi
/// Tüm gelir/giderleri grid'de gösterir
/// Sürükle-bırak ile gruplama, düzenleme modu, filtreleme
class VaultsScreen extends ConsumerWidget {
  const VaultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTransactions = ref.watch(mockTransactionsProvider);
    final groups = ref.watch(transactionGroupsProvider);
    final filter = ref.watch(transactionFilterProvider);
    final isEditMode = ref.watch(editModeProvider);

    // Filtreleme
    final filteredTransactions = allTransactions.where((t) {
      if (filter == TransactionFilter.income) return t.isIncome;
      if (filter == TransactionFilter.expense) return !t.isIncome;
      return true;
    }).toList();

    // Grupsuz işlemler (hiçbir gruba ait olmayan)
    final ungroupedTx = filteredTransactions
        .where((t) => t.groupId == null)
        .toList();

    // Filtreye uyan gruplar
    final filteredGroups = groups.where((g) {
      return g.transactionIds.any((id) {
        final tx = allTransactions.where((t) => t.id == id).firstOrNull;
        if (tx == null) return false;
        if (filter == TransactionFilter.income) return tx.isIncome;
        if (filter == TransactionFilter.expense) return !tx.isIncome;
        return true;
      });
    }).toList();

    // Toplam gelir / gider hesapla
    final totalIncome = allTransactions
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = allTransactions
        .where((t) => !t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);

    // Grid öğeleri: önce gruplar, sonra grupsuz işlemler
    final List<dynamic> gridItems = [...filteredGroups, ...ungroupedTx];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.paddingMedium),

          // === BAŞLIK + EDIT MODE BUTONU ===
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kasalar',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              // Edit modu toggle
              GestureDetector(
                onTap: () {
                  ref.read(editModeProvider.notifier).state = !isEditMode;
                  if (!isEditMode) {
                    HapticFeedback.mediumImpact();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isEditMode
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isEditMode
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.darkShadow.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isEditMode ? 'Bitti' : 'Düzenle',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isEditMode
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSmall),

          // === TOPLAM GELİR / GİDER ÖZETİ ===
          Row(
            children: [
              _SummaryChip(
                label: 'Gelir',
                amount: '+₺${totalIncome.toStringAsFixed(0)}',
                color: Colors.green,
              ),
              const SizedBox(width: 10),
              _SummaryChip(
                label: 'Gider',
                amount: '-₺${totalExpense.toStringAsFixed(0)}',
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // === FİLTRE BUTONLARI ===
          Row(
            children: [
              _FilterChip(
                label: 'Tümü',
                isActive: filter == TransactionFilter.all,
                onTap: () =>
                    ref.read(transactionFilterProvider.notifier).state =
                        TransactionFilter.all,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Gelir',
                isActive: filter == TransactionFilter.income,
                onTap: () =>
                    ref.read(transactionFilterProvider.notifier).state =
                        TransactionFilter.income,
                activeColor: Colors.green,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Gider',
                isActive: filter == TransactionFilter.expense,
                onTap: () =>
                    ref.read(transactionFilterProvider.notifier).state =
                        TransactionFilter.expense,
                activeColor: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingMedium),

          // === GRID ===
          Expanded(
            child: gridItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 60,
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Henüz işlem yok',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: gridItems.length,
                    itemBuilder: (context, index) {
                      final item = gridItems[index];

                      if (item is TransactionGroup) {
                        return _buildGroupItem(context, ref, item, isEditMode);
                      } else if (item is MockTransaction) {
                        return _buildTransactionItem(
                          context,
                          ref,
                          item,
                          isEditMode,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Tek işlem grid öğesi — drag + drop target
  Widget _buildTransactionItem(
    BuildContext context,
    WidgetRef ref,
    MockTransaction tx,
    bool isEditMode,
  ) {
    final card = TransactionCard(
      transaction: tx,
      isEditMode: isEditMode,
      onDelete: () async {
        if (tx.dbId != null) {
          await DatabaseService.deleteTransaction(tx.dbId!);
        }
        HapticFeedback.lightImpact();
      },
      onEdit: () {
        // İşlemi düzenlemek için transaction sheet'i bilgilerle aç
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => AddTransactionSheet(
            initialId: tx.dbId,
            initialName: tx.name,
            initialAmount: tx.amount,
            initialMinAmount: tx.minAmount,
            initialMaxAmount: tx.maxAmount,
            initialIsIncome: tx.isIncome,
          ),
        );
      },
    );

    if (!isEditMode) return card;

    // Edit modda: Sürüklenebilir + Bırakılabilir hedef
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != tx.id,
      onAcceptWithDetails: (details) {
        final draggedId = details.data;
        // İki işlemi birleştirerek grup oluştur
        final groupId = ref
            .read(transactionGroupsProvider.notifier)
            .createGroup(draggedId, tx.id);
        ref
            .read(transactionGroupingProvider.notifier)
            .setGroupId(draggedId, groupId);
        ref
            .read(transactionGroupingProvider.notifier)
            .setGroupId(tx.id, groupId);
        HapticFeedback.heavyImpact();
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return LongPressDraggable<String>(
          data: tx.id,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 100,
              height: 110,
              child: Opacity(
                opacity: 0.85,
                child: TransactionCard(transaction: tx),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: card),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
              border: isHovering
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
              boxShadow: isHovering
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: card,
          ),
        );
      },
    );
  }

  /// Grup grid öğesi — tap to open detail + drag target
  Widget _buildGroupItem(
    BuildContext context,
    WidgetRef ref,
    TransactionGroup group,
    bool isEditMode,
  ) {
    final allTx = ref.watch(mockTransactionsProvider);
    final groupTx = allTx
        .where((t) => group.transactionIds.contains(t.id))
        .toList();

    final card = GroupCard(
      group: group,
      transactions: groupTx,
      isEditMode: isEditMode,
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => GroupDetailSheet(group: group),
        );
      },
      onDelete: () {
        // Gruptaki tüm işlemlerin groupId'sini null yap
        for (final txId in group.transactionIds) {
          ref.read(transactionGroupingProvider.notifier).setGroupId(txId, null);
        }
        ref.read(transactionGroupsProvider.notifier).deleteGroup(group.id);
        HapticFeedback.lightImpact();
      },
    );

    if (!isEditMode) return card;

    // Edit modda grubun üstüne de bırakılabilmeli (gruba ekleme)
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          !group.transactionIds.contains(details.data),
      onAcceptWithDetails: (details) {
        final draggedId = details.data;
        ref
            .read(transactionGroupsProvider.notifier)
            .addToGroup(group.id, draggedId);
        ref
            .read(transactionGroupingProvider.notifier)
            .setGroupId(draggedId, group.id);
        HapticFeedback.heavyImpact();
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
            border: isHovering
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: card,
        );
      },
    );
  }
}

/// Gelir/Gider özet chip'i
class _SummaryChip extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filtre chip'i (Tümü / Gelir / Gider)
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? activeColor;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.4)
                : AppColors.darkShadow.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
