import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../core/utils/currency_utils.dart';
import '../../shared/widgets/fluid_container.dart';
import '../../shared/widgets/fluid_sheet.dart';
import '../../shared/widgets/fluid_dialog.dart';
import '../../shared/widgets/carved_container.dart';
import 'vaults_providers.dart';
import 'widgets/transaction_card.dart';
import '../transactions/add_transaction_sheet.dart';
import 'widgets/visibility_management_sheet.dart';
import 'widgets/vault_detail_sheet.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final scalingFactor = (screenHeight / 812.0).clamp(0.75, 1.0);

    FluidSheet.show(
      context: context,
      title: tx.name,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.5 + (0.5 * value),
                child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
              );
            },
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140 * scalingFactor,
                    height: 140 * scalingFactor,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          tx.color.withValues(alpha: 0.3),
                          tx.color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 100 * scalingFactor,
                    height: 100 * scalingFactor,
                    decoration: BoxDecoration(
                      color: tx.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(36 * scalingFactor),
                      border: Border.all(
                        color: tx.color.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(tx.icon, size: 48 * scalingFactor, color: tx.color),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16), // Reduced from 24

          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tx.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (localizedCategoryName(tx.categoryId, l10n) ?? l10n.all)
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: tx.color,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '₺${CurrencyUtils.formatFullAmount(tx.amount)}',
                    style: TextStyle(
                      fontSize: 56 * scalingFactor, // Scaled font size
                      fontWeight: FontWeight.w900,
                      color: tx.isIncome
                          ? AppColors.getIncome(context)
                          : AppColors.getExpense(context),
                      letterSpacing: -3,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
            ),
  
            SizedBox(height: 32 * scalingFactor), // Reduced from 40

          ...List.generate(3, (index) {
            final values = [
              tx.groupIds.isNotEmpty
                  ? tx.groupIds.first.replaceFirst('v_', '')
                  : l10n.mainVault,
              localizedCategoryName(tx.categoryId, l10n) ?? "-",
              _getPeriodLabel(tx.periodType, l10n),
            ];
            final icons = [
              Icons.account_balance_wallet_rounded,
              Icons.category_rounded,
              Icons.replay_rounded,
            ];
            final displayLabels = [l10n.vaults, l10n.category, l10n.period];

            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Interval(
                0.4 + (index * 0.1),
                1.0,
                curve: Curves.easeOutCubic,
              ),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Padding(
                padding: EdgeInsets.only(bottom: 8 * scalingFactor), // Reduced from 12
                child: FluidContainer(
                  padding: EdgeInsets.all(16 * scalingFactor), // Reduced from 18
                  borderRadius: 24,
                  isGlass: true,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.015),
                  child: Row(
                    children: [
                      Container(
                        width: 36 * scalingFactor, // Reduced from 40
                        height: 36 * scalingFactor, // Reduced from 40
                        decoration: BoxDecoration(
                          color: tx.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12 * scalingFactor), // Reduced from 14
                        ),
                        child: Icon(icons[index], size: 18 * scalingFactor, color: tx.color), // Reduced from 20
                      ),
                      SizedBox(width: 14 * scalingFactor),
                      Text(
                        displayLabels[index],
                        style: TextStyle(
                          fontSize: 13, // Reduced from 14
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        values[index],
                        style: TextStyle(
                          fontSize: 15, // Reduced from 16
                          fontWeight: FontWeight.w800,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          SizedBox(height: 24 * scalingFactor), // Reduced from 32

          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: const Interval(0.8, 1.0, curve: Curves.easeOutCubic),
            builder: (context, value, child) {
              return Opacity(opacity: value, child: child);
            },
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _handleTransactionLongPress(context, ref, tx);
                    },
                    child: FluidContainer(
                      padding: EdgeInsets.symmetric(vertical: 14 * scalingFactor), // Reduced from 16
                      borderRadius: 20,
                      color: AppColors.getPrimary(
                        context,
                      ).withValues(alpha: 0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 20,
                            color: AppColors.getPrimary(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.edit,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.getPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await showFluidDialog<bool>(
                      context: context,
                      accentColor: AppColors.error,
                      icon: const Icon(Icons.delete_forever_rounded),
                      title: Text(l10n.permanentDelete),
                      content: Text(l10n.permanentDeleteDesc),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            l10n.cancel,
                            style: TextStyle(
                              color: AppColors.getTextSecondary(context),
                            ),
                          ),
                        ),
                        FluidDialogButton(
                          label: l10n.ok,
                          onTap: () => Navigator.pop(context, true),
                          color: AppColors.error,
                        ),
                      ],
                    );
                    if (confirm == true) {
                      await DatabaseService.deleteTransaction(tx.dbId!);
                      HapticFeedback.mediumImpact();
                    }
                  },
                  child: FluidContainer(
                    width: 50 * scalingFactor, // Reduced from 56
                    height: 50 * scalingFactor, // Reduced from 56
                    borderRadius: 20,
                    color: AppColors.error.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.delete_sweep_rounded,
                      color: AppColors.error,
                      size: 24 * scalingFactor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
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

    showTransactionActionMenu(
      context,
      name: tx.name,
      isInVault: tx.groupIds.isNotEmpty,
      showOnDashboard: tx.showOnDashboard,
      onToggleDashboard: (val) async {
        final record = await DatabaseService.getTransaction(tx.dbId!);
        if (record != null) {
          record.showOnDashboard = val;
          await DatabaseService.updateTransaction(record);
          HapticFeedback.mediumImpact();
        }
      },
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
          ),
        );
      },
      onRemoveFromVault: () async {
        final groupingHelper = ref.read(transactionGroupingProvider);
        if (tx.groupIds.isNotEmpty) {
          final vaultToRemove = selectedVaultId ?? tx.groupIds.first;
          await groupingHelper.removeFromVault(tx.id, vaultToRemove);
          HapticFeedback.mediumImpact();
        }
      },
      onDelete: () async {
        final confirm = await showFluidDialog<bool>(
          context: context,
          accentColor: AppColors.error,
          icon: const Icon(Icons.delete_forever_rounded),
          title: Text(AppLocalizations.of(context)!.permanentDelete),
          content: Text(AppLocalizations.of(context)!.permanentDeleteDesc),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(color: AppColors.getTextSecondary(context)),
              ),
            ),
            FluidDialogButton(
              label: AppLocalizations.of(context)!.ok,
              onTap: () => Navigator.pop(context, true),
              color: AppColors.error,
            ),
          ],
        );
        if (confirm == true) {
          await DatabaseService.deleteTransaction(tx.dbId!);
          HapticFeedback.mediumImpact();
        }
      },
    );
  }

  void _showVaultManagementSheet(BuildContext context) {
    FluidSheet.show(
      context: context,
      title: AppLocalizations.of(context)!.visibilityManagement,
      child: const VisibilityManagementSheet(),
    );
  }

  void _showAddVaultSheet(BuildContext context) {
    HapticFeedback.heavyImpact();
    FluidSheet.show(
      context: context,
      title: 'Yeni Kasa',
      child: const VisibilityManagementSheet(startInAddMode: true),
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
