import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../core/utils/currency_utils.dart';
import '../../shared/widgets/fluid_container.dart';
import '../../shared/widgets/fluid_sheet.dart';
import 'vaults_providers.dart';
import 'widgets/transaction_card.dart';
import '../transactions/add_transaction_sheet.dart'; 
import 'widgets/vault_management_sheet.dart';
import '../dashboard/dashboard_providers.dart';

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
    final isEditMode = ref.watch(editModeProvider);
    final selectedVaultId = ref.watch(selectedVaultProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final activeColor = ref.watch(rotaryColorProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: Stack(
        children: [
          if (isDark) ...[
            Positioned(top: -50, left: -50, child: _LiquidBlob(color: activeColor.withValues(alpha: 0.15), size: 400)),
            Positioned(bottom: 100, right: -100, child: _LiquidBlob(color: AppColors.getSecondary(context).withValues(alpha: 0.1), size: 500)),
          ],

          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // TRUE MORPHING SMART DECK HEADER
              SliverPersistentHeader(
                pinned: true,
                delegate: _TrueMorphDeckHeaderDelegate(
                  groups: groups,
                  allTransactions: allTransactions,
                  selectedVaultId: selectedVaultId,
                  onVaultSelect: (id) => ref.read(selectedVaultProvider.notifier).state = id,
                  activeColor: activeColor,
                  isEditMode: isEditMode,
                  onEditToggle: () => ref.read(editModeProvider.notifier).state = !isEditMode,
                  onManageVaults: () => _showVaultManagementSheet(context),
                  l10n: l10n,
                ),
              ),

              // Filtreler & İşlemler
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.paddingMedium, 24, AppSizes.paddingMedium, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("FİLTRELEME", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.withValues(alpha: 0.5), letterSpacing: 2)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _FluidFilterChip(label: l10n.all, isActive: filter == TransactionFilter.all, onTap: () => ref.read(transactionFilterProvider.notifier).state = TransactionFilter.all, activeColor: activeColor),
                          const SizedBox(width: 8),
                          _FluidFilterChip(label: l10n.income, isActive: filter == TransactionFilter.income, onTap: () => ref.read(transactionFilterProvider.notifier).state = TransactionFilter.income, activeColor: AppColors.getIncome(context)),
                          const SizedBox(width: 8),
                          _FluidFilterChip(label: l10n.expense, isActive: filter == TransactionFilter.expense, onTap: () => ref.read(transactionFilterProvider.notifier).state = TransactionFilter.expense, activeColor: AppColors.getExpense(context)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        child: Row(
                          children: [
                            _FluidFilterChip(label: l10n.allTime, isActive: selectedPeriod == null, onTap: () => ref.read(selectedPeriodProvider.notifier).state = null, activeColor: activeColor),
                            const SizedBox(width: 8),
                            ...[1, 2, 3].map((p) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FluidFilterChip(
                                label: _getPeriodLabel(p, l10n),
                                isActive: selectedPeriod == p,
                                onTap: () => ref.read(selectedPeriodProvider.notifier).state = p,
                                activeColor: activeColor,
                              ),
                            )),
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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CarvedContainer(
                          size: 100,
                          child: Icon(Icons.auto_graph_rounded, size: 40, color: activeColor.withValues(alpha: isDark ? 0.3 : 0.1)),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          l10n.noTransactions.toUpperCase(), 
                          style: TextStyle(
                            color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.3), 
                            fontSize: 14, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 2
                          )
                        ),
                        const SizedBox(height: 100), // Navigasyondan kurtarmak için yukarı itiyoruz
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.paddingMedium, 0, AppSizes.paddingMedium, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx = filteredTransactions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TransactionCard(
                            transaction: tx,
                            onTap: () => _showTransactionDetail(context, tx),
                            onLongPress: () => _handleTransactionLongPress(context, ref, tx),
                          ),
                        );
                      },
                      childCount: filteredTransactions.length,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context, Color activeColor) {
    return GestureDetector(
      onTap: () => _showAddTransactionSheet(context),
      child: FluidContainer(
        width: 64, height: 64,
        borderRadius: 24,
        color: activeColor,
        isGlass: false,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    HapticFeedback.heavyImpact();
    FluidSheet.show(
      context: context,
      title: AppLocalizations.of(context)!.addTransaction,
      child: const AddTransactionSheet(),
    );
  }

  String _getPeriodLabel(int period, AppLocalizations l10n) {
    switch (period) {
      case 0: return l10n.oneTime;
      case 1: return l10n.weekly;
      case 4: return l10n.every2Weeks;
      case 5: return l10n.every3Weeks;
      case 2: return l10n.monthly;
      case 6: return l10n.every3Months;
      case 7: return l10n.every6Months;
      case 3: return l10n.yearly;
      default: return '';
    }
  }

  void _showTransactionDetail(BuildContext context, TransactionUI tx) {
    FluidSheet.show(
      context: context,
      title: tx.name,
      child: Column(
        children: [
          FluidContainer(
            padding: const EdgeInsets.all(24),
            isGlass: true,
            color: tx.color.withValues(alpha: 0.1),
            child: Column(
              children: [
                Icon(tx.icon, size: 48, color: tx.color),
                const SizedBox(height: 16),
                Text('₺${CurrencyUtils.formatFullAmount(tx.amount)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _handleTransactionLongPress(BuildContext context, WidgetRef ref, TransactionUI tx) {
    if (tx.dbId == null) return;
    HapticFeedback.heavyImpact();
    showTransactionActionMenu(
      context,
      name: tx.name,
      isInVault: tx.groupId != null,
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
            initialVaultId: tx.groupId != null ? int.tryParse(tx.groupId!.replaceFirst('v_', '')) : null,
            initialCategoryId: tx.categoryId,
          ),
        );
      },
      onDelete: () async {
        final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(backgroundColor: AppColors.getSurface(context), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), title: Text(AppLocalizations.of(context)!.permanentDelete, style: const TextStyle(fontWeight: FontWeight.w900)), content: Text(AppLocalizations.of(context)!.permanentDeleteDesc), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.ok, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w900)))]));
        if (confirm == true) { await DatabaseService.deleteTransaction(tx.dbId!); HapticFeedback.mediumImpact(); }
      },
    );
  }

  void _showVaultManagementSheet(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => const VaultManagementSheet());
  }
}

/// GERÇEK MORPHING DESTE DELEGATE
class _TrueMorphDeckHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<TransactionGroup> groups;
  final List<TransactionUI> allTransactions;
  final String? selectedVaultId;
  final Function(String?) onVaultSelect;
  final Color activeColor;
  final bool isEditMode;
  final VoidCallback onEditToggle;
  final VoidCallback onManageVaults;
  final AppLocalizations l10n;

  _TrueMorphDeckHeaderDelegate({
    required this.groups,
    required this.allTransactions,
    required this.selectedVaultId,
    required this.onVaultSelect,
    required this.activeColor,
    required this.isEditMode,
    required this.onEditToggle,
    required this.onManageVaults,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final topPadding = MediaQuery.of(context).padding.top;
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final deckItems = [null, ...groups.map((g) => g.id)];
    final currentIndex = deckItems.indexOf(selectedVaultId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Arka plan daha hızlı opak olsun — konteyner erirken bar zaten orada
    final bgAlpha = Curves.easeOutQuad.transform((progress * 1.6).clamp(0.0, 1.0));

    return SizedBox.expand(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: bgAlpha * 20,
            sigmaY: bgAlpha * 20,
          ),
          child: Container(
            color: AppColors.getBackground(context).withValues(alpha: bgAlpha * 0.15),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // THE TRANSFORMING DECK
            Positioned(
              top: lerpDouble(topPadding + 80, topPadding + 4, progress)!,
              left: 0, right: 0,
              height: lerpDouble(300, 56, progress)!,
              child: _VaultCardStack(
                deckItems: deckItems,
                allTransactions: allTransactions,
                currentIndex: currentIndex,
                onVaultSelect: onVaultSelect,
                activeColor: activeColor,
                l10n: l10n,
                groups: groups,
                morphProgress: progress,
              ),
            ),

            // AppBar Başlığı — sola kayarak kaybolur
            Positioned(
              left: 20 - (progress * 100),
              top: topPadding + 10,
              child: Opacity(
                opacity: (1 - progress * 4).clamp(0.0, 1.0),
                child: Text(l10n.vaults, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
              ),
            ),

            // Aksiyon Butonları — sağa kayarak kaybolur
            Positioned(
              right: 20 - (progress * 100),
              top: topPadding + 10,
              child: Opacity(
                opacity: (1 - progress * 4).clamp(0.0, 1.0),
                child: Row(
                  children: [
                    _HeaderIconButton(icon: Icons.account_balance_wallet_rounded, onTap: onManageVaults),
                    const SizedBox(width: 8),
                    _HeaderIconButton(icon: isEditMode ? Icons.check_rounded : Icons.edit_note_rounded, onTap: onEditToggle, isSelected: isEditMode, activeColor: activeColor),
                  ],
                ),
              ),
            ),

            // Organik alt çizgi — compact modda konteyneri değil, ince bir çizgi
            if (progress > 0.6)
              Positioned(
                bottom: 0,
                left: 20,
                right: 20,
                child: Opacity(
                  opacity: ((progress - 0.6) * 2.5).clamp(0.0, 1.0),
                  child: Container(
                    height: 0.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                          (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.2, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  @override
  double get maxExtent => 420;
  @override
  double get minExtent => 60 + 40; // 40 top padding offset
 // topPadding header içinde hallediliyor
  @override
  bool shouldRebuild(covariant _TrueMorphDeckHeaderDelegate oldDelegate) => true;
}

class _VaultCardStack extends StatefulWidget {
  final List<String?> deckItems;
  final List<TransactionUI> allTransactions;
  final int currentIndex;
  final Function(String?) onVaultSelect;
  final Color activeColor;
  final AppLocalizations l10n;
  final List<TransactionGroup> groups;
  final double morphProgress;

  const _VaultCardStack({required this.deckItems, required this.allTransactions, required this.currentIndex, required this.onVaultSelect, required this.activeColor, required this.l10n, required this.groups, required this.morphProgress});

  @override
  State<_VaultCardStack> createState() => _VaultCardStackState();
}

class _VaultCardStackState extends State<_VaultCardStack> {
  late PageController _pageController;
  int? _lastTargetIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.currentIndex, viewportFraction: 0.70);
    _lastTargetIndex = widget.currentIndex;
  }
  
  @override
  void didUpdateWidget(covariant _VaultCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && _pageController.hasClients) {
      if (_lastTargetIndex != widget.currentIndex) {
        _lastTargetIndex = widget.currentIndex;
        _pageController.animateToPage(widget.currentIndex, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompact = widget.morphProgress > 0.8;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification && !isCompact) {
          final page = _pageController.page?.round() ?? 0;
          if (_lastTargetIndex != page) {
            _lastTargetIndex = page;
            HapticFeedback.selectionClick();
            widget.onVaultSelect(widget.deckItems[page]);
          }
        }
        return true;
      },
      child: PageView.builder(
        controller: _pageController,
        physics: isCompact ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: widget.deckItems.length,
        itemBuilder: (context, index) {
          final vaultId = widget.deckItems[index];
          final txs = vaultId == null ? widget.allTransactions : widget.allTransactions.where((t) => t.groupId == vaultId).toList();
          final income = txs.where((t) => t.isIncome).fold<double>(0, (sum, t) => sum + t.monthlyEquivalent);
          final expense = txs.where((t) => !t.isIncome).fold<double>(0, (sum, t) => sum + t.monthlyEquivalent);
          final balance = income - expense;

          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                double diff = (_pageController.page! - index).abs();
                value = (1 - (diff * 0.15)).clamp(0.85, 1.0);
              } else {
                value = index == widget.currentIndex ? 1.0 : 0.85;
              }
              
              final isCurrent = index == widget.currentIndex;
              final cardOpacity = isCurrent ? 1.0 : (1 - widget.morphProgress * 2).clamp(0.0, 1.0);

              return Center(
                child: Opacity(
                  opacity: cardOpacity * (isCurrent ? 1.0 : (value * 2 - 1).clamp(0.5, 1.0)),
                  child: Transform.scale(
                    scale: value,
                    child: RepaintBoundary(
                      child: _IntegratedVaultCard(
                        vaultId: vaultId,
                        income: income,
                        expense: expense,
                        balance: balance,
                        txs: txs,
                        activeColor: widget.activeColor,
                        l10n: widget.l10n,
                        vaultName: index == 0 ? widget.l10n.mainVault : widget.groups[index - 1].name,
                        morphProgress: widget.morphProgress,
                        isCurrent: isCurrent,
                      ),
                    ),
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

class _IntegratedVaultCard extends StatelessWidget {
  final String? vaultId;
  final double income;
  final double expense;
  final double balance;
  final List<TransactionUI> txs;
  final Color activeColor;
  final AppLocalizations l10n;
  final String vaultName;
  final double morphProgress;
  final bool isCurrent;

  const _IntegratedVaultCard({
    required this.vaultId, 
    required this.income,
    required this.expense,
    required this.balance,
    required this.txs,
    required this.activeColor, 
    required this.l10n, 
    required this.vaultName, 
    required this.morphProgress, 
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // --- Sizes ---
    final double widthT = Curves.easeOutQuad.transform(morphProgress);
    final double cardWidth = lerpDouble(screenWidth * 0.70, screenWidth, widthT)!;
    final double cardHeight = lerpDouble(280, 56, morphProgress)!;
    
    // --- FluidContainer dekorasyon opaklığı — tüm container fade olur ---
    // Bu FluidContainer'ın kendi iç alpha sorununu tamamen bypass eder
    final double decorationOpacity = (1 - morphProgress * 3).clamp(0.0, 1.0); // progress 0.33'te tamamen kaybolur
    final double cardRadius = lerpDouble(32, 0, Curves.easeInQuad.transform((morphProgress * 2.5).clamp(0.0, 1.0)))!;
    
    // --- İçerik fazları ---
    final double secondaryOpacity = (1 - morphProgress * 5).clamp(0.0, 1.0); // 0→0.2 kaybol
    final double primaryMorph = Curves.easeInOutCubic.transform((morphProgress * 1.4).clamp(0.0, 1.0));
    
    final double hPad = lerpDouble(24, 20, morphProgress)!;
    
    // Effective width — OverflowBox ile PageView'ın %70 sınırını aşıyoruz
    final double effectiveWidth = isCurrent ? cardWidth : screenWidth * 0.70;
    
    return OverflowBox(
      maxWidth: effectiveWidth,
      maxHeight: cardHeight,
      child: SizedBox(
        width: effectiveWidth,
        height: cardHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // === DEKORASYON KATMANI — FluidContainer tüm dekorasyonla birlikte fade olur ===
            if (decorationOpacity > 0.01)
              Positioned.fill(
                child: Opacity(
                  opacity: decorationOpacity,
                  child: FluidContainer(
                    isGlass: morphProgress < 0.15, // Blur'u çok erken kapat — gri arkaplan yaratıyordu
                    isConvex: morphProgress < 0.15,
                    borderRadius: cardRadius,
                    color: isCurrent ? null : AppColors.getSurface(context).withValues(alpha: 0.5),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            
            // === İÇERİK KATMANI ===
            Positioned(
              left: hPad, right: hPad,
              top: 0, bottom: 0,
              child: _buildMorphContent(context, primaryMorph, secondaryOpacity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMorphContent(BuildContext context, double primaryMorph, double secondaryOpacity) {
    final hasFlexibleTx = txs.any((t) => t.minAmount != null || t.maxAmount != null);
    
    // Font boyutları — smooth lerp
    final double titleFontSize = lerpDouble(11, 18, primaryMorph)!;
    final double balanceFontSize = lerpDouble(42, 16, primaryMorph)!;
    final double titleLetterSpacing = lerpDouble(2, -0.5, primaryMorph)!;
    
    // Badge props — smooth lerp  
    final double badgePadH = lerpDouble(0, 12, primaryMorph)!;
    final double badgePadV = lerpDouble(0, 6, primaryMorph)!;
    final double badgeBgAlpha = primaryMorph * 0.12;
    
    // Renk geçişi
    final Color? titleColor = primaryMorph < 0.6
        ? activeColor.withValues(alpha: lerpDouble(0.7, 1.0, primaryMorph)!)
        : null;
    
    // Pozisyon hesabı — Stack içinde her eleman kendi yerinde
    // Genişken: Title en üstte, ortada. Balance altında, ortada. Secondary en altta.
    // Compact: Title sola yapışık, dikey ortada. Balance sağa yapışık, dikey ortada.
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        
        // Title Y pozisyonu: genişken üst kısımda, compact'ta dikey ortada
        final double titleExpandedTop = h * 0.15;
        final double titleCompactTop = (h - titleFontSize) / 2 - 2; // Tam ortada
        final double titleTop = lerpDouble(titleExpandedTop, titleCompactTop, primaryMorph)!;
        
        // Balance Y pozisyonu: genişken title altında, compact'ta dikey ortada
        final double balanceExpandedTop = titleExpandedTop + titleFontSize + 8;
        final double balanceCompactTop = (h - balanceFontSize) / 2 - 2;
        final double balanceTop = lerpDouble(balanceExpandedTop, balanceCompactTop, primaryMorph)!;
        
        // Secondary Y pozisyonu: genişken balance altında
        final double secondaryTop = balanceExpandedTop + balanceFontSize + 24;
        
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // === TITLE ===
            Positioned(
              left: 0, right: 0,
              top: titleTop,
              child: Align(
                alignment: Alignment.lerp(Alignment.center, Alignment.centerLeft, primaryMorph)!,
                child: Text(
                  primaryMorph < 0.4 ? vaultName.toUpperCase() : vaultName,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: titleLetterSpacing,
                    color: titleColor,
                  ),
                ),
              ),
            ),
            
            // === BALANCE ===
            Positioned(
              left: 0, right: 0,
              top: balanceTop,
              child: Align(
                alignment: Alignment.lerp(Alignment.center, Alignment.centerRight, primaryMorph)!,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: badgePadH, vertical: badgePadV),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: badgeBgAlpha),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    primaryMorph > 0.5
                      ? '₺${CurrencyUtils.formatAmount(balance)}'
                      : '₺${CurrencyUtils.formatFullAmount(balance)}',
                    style: TextStyle(
                      fontSize: balanceFontSize,
                      fontWeight: FontWeight.w900,
                      color: activeColor,
                      letterSpacing: lerpDouble(-2, 0, primaryMorph)!,
                    ),
                  ),
                ),
              ),
            ),
            
            // === SECONDARY STATS ===
            if (secondaryOpacity > 0.01)
              Positioned(
                left: 0, right: 0,
                top: secondaryTop,
                child: Opacity(
                  opacity: secondaryOpacity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildMiniStat(l10n.income, income, AppColors.getIncome(context))),
                          Container(width: 1, height: 30, color: activeColor.withValues(alpha: 0.1)),
                          Expanded(child: _buildMiniStat(l10n.expense, expense, AppColors.getExpense(context))),
                        ],
                      ),
                      if (hasFlexibleTx) ...[
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, thickness: 0.5)),
                        _buildRangeStats(txs),
                      ],
                      const SizedBox(height: 12),
                      const Icon(Icons.unfold_more_rounded, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMiniStat(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey.withValues(alpha: 0.6), letterSpacing: 1)),
        const SizedBox(height: 4),
        Text('₺${CurrencyUtils.formatAmount(amount)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildRangeStats(List<TransactionUI> txs) {
    final minNet = txs.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.minMonthlyEquivalent) - txs.where((t) => !t.isIncome).fold<double>(0, (s, t) => s + t.maxMonthlyEquivalent);
    final maxNet = txs.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.maxMonthlyEquivalent) - txs.where((t) => !t.isIncome).fold<double>(0, (s, t) => s + t.minMonthlyEquivalent);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildRangeStat("En Kötü", minNet, Colors.orange),
        _buildRangeStat("En İyi", maxNet, Colors.blue),
      ],
    );
  }

  Widget _buildRangeStat(String label, double amount, Color color) {
    return Row(
      children: [
        Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text('₺${CurrencyUtils.formatAmount(amount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
      ],
    );
  }
}

class _FluidFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  const _FluidFilterChip({required this.label, required this.isActive, required this.onTap, required this.activeColor});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FluidContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 16,
        isGlass: true,
        borderWidth: isActive ? 2 : 1,
        color: isActive ? activeColor.withValues(alpha: 0.1) : null,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            color: isActive ? activeColor : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
  final Color? activeColor;
  const _HeaderIconButton({required this.icon, required this.onTap, this.isSelected = false, this.activeColor});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FluidContainer(padding: const EdgeInsets.all(10), borderRadius: 14, isGlass: true, color: isSelected ? (activeColor ?? AppColors.getPrimary(context)).withValues(alpha: 0.1) : null, child: Icon(icon, size: 20, color: isSelected ? activeColor : Colors.grey)),
    );
  }
}

class _LiquidBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _LiquidBlob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)])), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container(color: Colors.transparent)));
  }
}

class _CarvedContainer extends StatelessWidget {
  final double size;
  final Widget child;
  const _CarvedContainer({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.getBackground(context);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(32),
        // Göçük efekti için gölgeleri ters çeviriyoruz (Dış gölge yerine içe yakın gölge simülasyonu)
        boxShadow: isDark ? [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            offset: const Offset(2, 2),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(-4, -4),
            blurRadius: 10,
          ),
        ] : [
          BoxShadow(
            color: Colors.white,
            offset: const Offset(2, 2),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            offset: const Offset(-4, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(1), // İnce bir kenarlık çizgisi
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [
              Colors.black.withValues(alpha: 0.3), // Üst sol daha karanlık (derinlik)
              bgColor,                             // Orta bakiye
              Colors.white.withValues(alpha: 0.03), // Alt sağ hafif ışık (kenar)
            ] : [
              Colors.grey.withValues(alpha: 0.2),
              bgColor,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Opacity(
            opacity: 0.6, // İkonun da yüzeye gömülü durması için opaklığı azaltıyoruz
            child: child,
          ),
        ),
      ),
    );
  }
}
