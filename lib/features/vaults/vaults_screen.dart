import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../shared/widgets/fluid_sheet.dart';
import '../../shared/widgets/precision_dialog.dart';
import '../../shared/widgets/carved_container.dart';
import 'vaults_providers.dart';
import 'widgets/transaction_card.dart';
import '../transactions/add_transaction_sheet.dart';
import 'widgets/vault_visibility_sheet.dart';
import 'widgets/add_vault_sheet.dart';
import 'widgets/vault_detail_sheet.dart';
import 'widgets/transaction_detail_sheet.dart';
import '../dashboard/dashboard_providers.dart';
import 'widgets/liquid_blob.dart';
import 'widgets/header_delegate.dart';
import 'widgets/filter_chip.dart';
// Removed unused: import '../../shared/widgets/sliver_animation_spacer.dart';

class VaultsScreen extends ConsumerStatefulWidget {
  const VaultsScreen({super.key});

  @override
  ConsumerState<VaultsScreen> createState() => _VaultsScreenState();
}

class _VaultsScreenState extends ConsumerState<VaultsScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allTransactions = ref.watch(vaultTransactionsProvider);
    final groups = ref.watch(transactionGroupsProvider);
    final filter = ref.watch(transactionFilterProvider);
    final selectedVaultId = ref.watch(selectedVaultProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final activeColor = ref.watch(rotaryColorProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final vaultTransactions = selectedVaultId == null
        ? allTransactions
        : allTransactions
              .where((t) => t.groupIds.contains(selectedVaultId))
              .toList();

    var filteredTransactions = vaultTransactions.where((t) {
      if (filter == TransactionFilter.income) return t.isIncome;
      if (filter == TransactionFilter.expense) return !t.isIncome;
      return true;
    }).toList();

    if (selectedPeriod != null) {
      filteredTransactions = filteredTransactions
          .where((t) => t.periodType == selectedPeriod)
          .toList();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final scalingFactor = (screenHeight / 812.0).clamp(0.85, 1.0);

    // Header limitleri (header_delegate.dart ile uyumlu)
    const maxHeaderHeight = 420.0;
    const minHeaderHeight = 100.0;

    // (requiredContentHeight was unused and removed)


    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: Stack(
        children: [
          if (isDark) ...[
            Positioned(
              top: -50,
              left: -50,
              child: LiquidBlob(
                color: activeColor.withValues(alpha: 0.15),
                size: 400,
              ),
            ),
            Positioned(
              bottom: 100,
              right: -100,
              child: LiquidBlob(
                color: AppColors.getSecondary(context).withValues(alpha: 0.1),
                size: 500,
              ),
            ),
          ],

          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: TrueMorphDeckHeaderDelegate(
                  groups: groups,
                  allTransactions: allTransactions,
                  selectedVaultId: selectedVaultId,
                  onVaultSelect: (id) =>
                      ref.read(selectedVaultProvider.notifier).state = id,
                  activeColor: activeColor,
                  onManageVaults: () => _showVaultManagementSheet(context),
                  onAddVault: () => _showAddVaultSheet(context),
                  l10n: l10n,
                  onVaultTap: (id) => _showVaultDetail(context, id),
                  topPadding: MediaQuery.of(context).padding.top,
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingMedium,
                    24,
                    AppSizes.paddingMedium,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "FİLTRELEME",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey.withValues(alpha: 0.5),
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: AppSizes.paddingLarge * scalingFactor),
                      Row(
                        children: [
                          VaultFilterChip(
                            label: l10n.all,
                            isActive: filter == TransactionFilter.all,
                            onTap: () =>
                                ref
                                    .read(transactionFilterProvider.notifier)
                                    .state = TransactionFilter
                                    .all,
                            activeColor: activeColor,
                          ),
                          const SizedBox(width: 8),
                          VaultFilterChip(
                            label: l10n.income,
                            isActive: filter == TransactionFilter.income,
                            onTap: () =>
                                ref
                                    .read(transactionFilterProvider.notifier)
                                    .state = TransactionFilter
                                    .income,
                            activeColor: AppColors.getIncome(context),
                          ),
                          const SizedBox(width: 8),
                          VaultFilterChip(
                            label: l10n.expense,
                            isActive: filter == TransactionFilter.expense,
                            onTap: () =>
                                ref
                                    .read(transactionFilterProvider.notifier)
                                    .state = TransactionFilter
                                    .expense,
                            activeColor: AppColors.getExpense(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        child: Row(
                          children: [
                            VaultFilterChip(
                              label: l10n.allTime,
                              isActive: selectedPeriod == null,
                              onTap: () =>
                                  ref
                                          .read(selectedPeriodProvider.notifier)
                                          .state =
                                      null,
                              activeColor: activeColor,
                            ),
                            const SizedBox(width: 8),
                            ...[1, 2, 3].map(
                              (p) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: VaultFilterChip(
                                  label: _getPeriodLabel(p, l10n),
                                  isActive: selectedPeriod == p,
                                  onTap: () =>
                                      ref
                                              .read(
                                                selectedPeriodProvider.notifier,
                                              )
                                              .state =
                                          p,
                                  activeColor: activeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (filteredTransactions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: const Alignment(
                      0,
                      -0.4,
                    ), // İçeriği yukarı çektik
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1200),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return CarvedContainer(
                                size:
                                    100, // Biraz küçülttük ki daha rahat sığsın
                                child: Transform.scale(
                                  scale: 0.4 + (0.6 * value),
                                  child: Opacity(
                                    opacity: value.clamp(0.0, 1.0),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: Icon(
                              Icons.auto_graph_rounded,
                              size: 40,
                              color: activeColor.withValues(
                                alpha: isDark ? 0.3 : 0.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.noTransactions.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.3),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingMedium,
                    0,
                    AppSizes.paddingMedium,
                    20,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.35,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => TransactionCard(
                        transaction: filteredTransactions[index],
                        onTap: () => _showTransactionDetail(
                          context,
                          filteredTransactions[index],
                        ),
                        onLongPress: () => _handleTransactionLongPress(
                          context,
                          ref,
                          filteredTransactions[index],
                        ),
                      ),
                      childCount: filteredTransactions.length,
                    ),
                  ),
                ),

              // AKILLI BOŞLUK:
              // Eğer içerik zaten yeterince uzunsa (animasyonu tamamlatabiliyorsa) boşluk eklemez.
              // Eğer içerik kısaysa, tam animasyonun kapanacağı mesafe (320px) kadar alanı garanti eder.
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  // precedingScrollExtent o anki toplam layout boyutunu verir.
                  // scrollOffset ile toplayarak scroll=0 anındaki hayali tam boyutu buluyoruz.
                  final totalHeightAtStart =
                      constraints.precedingScrollExtent +
                      constraints.scrollOffset;
                  final targetHeight =
                      constraints.viewportMainAxisExtent +
                      (maxHeaderHeight - minHeaderHeight);
                  final gap = targetHeight - totalHeightAtStart;

                  return SliverToBoxAdapter(
                    child: SizedBox(height: gap > 0 ? gap : 0),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(int period, AppLocalizations l10n) {
    switch (period) {
      case 0:
        return l10n.oneTime;
      case 1:
        return l10n.weekly;
      case 4:
        return l10n.every2Weeks;
      case 5:
        return l10n.every3Weeks;
      case 2:
        return l10n.monthly;
      case 6:
        return l10n.every3Months;
      case 7:
        return l10n.every6Months;
      case 3:
        return l10n.yearly;
      default:
        return '';
    }
  }

  void _showTransactionDetail(BuildContext context, TransactionUI tx) {
    final l10n = AppLocalizations.of(context)!;
    final categoryName = localizedCategoryName(tx.categoryId, l10n) ?? l10n.all;
    final parentId = tx.categoryId?.split('_').take(2).join('_');
    final parentName = parentId != null ? localizedCategoryName(parentId, l10n) : null;
    final fullTitle = parentName != null && parentName != categoryName 
        ? '$parentName / $categoryName' 
        : categoryName;

    final selectedVaultId = ref.read(selectedVaultProvider);
    FluidSheet.show(
      context: context,
      title: fullTitle,
      child: TransactionDetailSheet(
        transaction: tx,
        onEdit: () {
          FluidSheet.show(
            context: context,
            title: AppLocalizations.of(context)!.edit,
            child: AddTransactionSheet(
              initialId: tx.dbId,
              initialName: tx.name,
              initialAmount: tx.amount,
              initialMinAmount: tx.minAmount,
              initialMaxAmount: tx.maxAmount,
              initialIsIncome: tx.isIncome,
              initialVaultIds: tx.groupIds
                  .map((vId) => int.parse(vId.replaceFirst('v_', '')))
                  .toList(),
              initialCategoryId: tx.categoryId,
              initialNote: tx.note,
              initialCurrency: tx.currency,
              initialPeriodType: tx.periodType,
              initialRecurrenceDay: tx.recurrenceDay,
              initialRecurrenceDate: tx.recurrenceDate,
              initialRecurrenceDuration: tx.recurrenceDuration,
            ),
          );
        },
        onDelete: () async {
          final confirm = await showPrecisionDialog<bool>(
            context: context,
            accentColor: AppColors.error,
            title: AppLocalizations.of(context)!.permanentDelete,
            content: AppLocalizations.of(context)!.permanentDeleteDesc,
            actions: [
              PrecisionDialogAction(
                label: AppLocalizations.of(context)!.cancel,
                onTap: () => Navigator.pop(context, false),
                isPrimary: false,
              ),
              PrecisionDialogAction(
                label: AppLocalizations.of(context)!.ok,
                onTap: () => Navigator.pop(context, true),
                isPrimary: true,
              ),
            ],
          );
          if (confirm == true) {
            await DatabaseService.deleteTransaction(tx.dbId!);
            HapticFeedback.mediumImpact();
          }
        },
        onRemoveFromVault: selectedVaultId != null ? () async {
          final record = await DatabaseService.getTransaction(tx.dbId!);
          if (record != null) {
            final vId = int.tryParse(selectedVaultId.replaceFirst('v_', ''));
            if (vId != null) {
              record.vaultIds = List<int>.from(record.vaultIds)..remove(vId);
              await DatabaseService.updateTransaction(record);
              HapticFeedback.mediumImpact();
            }
          }
        } : null,
        isInVault: tx.groupIds.isNotEmpty,
      ),
    );
  }

  void _handleTransactionLongPress(
    BuildContext context,
    WidgetRef ref,
    TransactionUI tx,
  ) {
    if (tx.dbId == null) return;
    HapticFeedback.heavyImpact();

    final selectedVaultId = ref.read(selectedVaultProvider);

    FluidSheet.show(
      context: context,
      title: tx.name,
      child: TransactionDetailSheet(
        transaction: tx,
        onEdit: () {
          FluidSheet.show(
            context: context,
            title: AppLocalizations.of(context)!.edit,
            child: AddTransactionSheet(
              initialId: tx.dbId,
              initialName: tx.name,
              initialAmount: tx.amount,
              initialMinAmount: tx.minAmount,
              initialMaxAmount: tx.maxAmount,
              initialIsIncome: tx.isIncome,
              initialVaultIds: tx.groupIds
                  .map((vId) => int.parse(vId.replaceFirst('v_', '')))
                  .toList(),
              initialCategoryId: tx.categoryId,
              initialNote: tx.note,
              initialCurrency: tx.currency,
              initialPeriodType: tx.periodType,
              initialRecurrenceDay: tx.recurrenceDay,
              initialRecurrenceDate: tx.recurrenceDate,
              initialRecurrenceDuration: tx.recurrenceDuration,
            ),
          );
        },
        onDelete: () async {
          final confirm = await showPrecisionDialog<bool>(
            context: context,
            accentColor: AppColors.error,
            title: AppLocalizations.of(context)!.permanentDelete,
            content: AppLocalizations.of(context)!.permanentDeleteDesc,
            actions: [
              PrecisionDialogAction(
                label: AppLocalizations.of(context)!.cancel,
                onTap: () => Navigator.pop(context, false),
                isPrimary: false,
              ),
              PrecisionDialogAction(
                label: AppLocalizations.of(context)!.ok,
                onTap: () => Navigator.pop(context, true),
                isPrimary: true,
              ),
            ],
          );
          if (confirm == true) {
            await DatabaseService.deleteTransaction(tx.dbId!);
            HapticFeedback.mediumImpact();
          }
        },
        onRemoveFromVault: selectedVaultId != null ? () async {
          final record = await DatabaseService.getTransaction(tx.dbId!);
          if (record != null) {
            final vId = int.tryParse(selectedVaultId.replaceFirst('v_', ''));
            if (vId != null) {
              record.vaultIds = List<int>.from(record.vaultIds)..remove(vId);
              await DatabaseService.updateTransaction(record);
              HapticFeedback.mediumImpact();
            }
          }
        } : null,
        isInVault: tx.groupIds.isNotEmpty,
      ),
    );
  }

  void _showVaultManagementSheet(BuildContext context) {
    FluidSheet.show(
      context: context,
      title: AppLocalizations.of(context)!.visibilityManagement,
      child: const VaultVisibilitySheet(),
    );
  }

  void _showAddVaultSheet(BuildContext context) {
    HapticFeedback.heavyImpact();
    FluidSheet.show(
      context: context,
      title: 'Yeni Kasa',
      child: const AddVaultSheet(),
    );
  }

  void _showVaultDetail(BuildContext context, String vaultId) {
    HapticFeedback.mediumImpact();
    FluidSheet.show(
      context: context,
      title: 'Kasa Detayı',
      child: VaultDetailSheet(vaultId: vaultId),
    );
  }
}
