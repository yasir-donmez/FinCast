import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../shared/widgets/fluid_container.dart';
import '../vaults_providers.dart';

class IntegratedVaultCard extends StatelessWidget {
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

  const IntegratedVaultCard({
    super.key,
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
    final double decorationOpacity = (1 - morphProgress * 3).clamp(0.0, 1.0); 
    final double cardRadius = lerpDouble(32, 0, Curves.easeInQuad.transform((morphProgress * 2.5).clamp(0.0, 1.0)))!;
    
    // --- İçerik fazları ---
    final double secondaryOpacity = (1 - morphProgress * 5).clamp(0.0, 1.0); 
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
            // === DEKORASYON KATMANI ===
            if (decorationOpacity > 0.01)
              Positioned.fill(
                child: Opacity(
                  opacity: decorationOpacity,
                  child: FluidContainer(
                    isGlass: morphProgress < 0.15,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final double titleFontSize = lerpDouble(11, 18, primaryMorph)!;
    final double balanceFontSize = lerpDouble(42, 16, primaryMorph)!;
    final double titleLetterSpacing = lerpDouble(2, -0.5, primaryMorph)!;
    
    final double badgePadH = lerpDouble(0, 12, primaryMorph)!;
    final double badgePadV = lerpDouble(0, 6, primaryMorph)!;
    final double badgeBgAlpha = primaryMorph * 0.12;
    
    final Color? titleColor = primaryMorph < 0.6
        ? activeColor.withValues(alpha: lerpDouble(0.7, 1.0, primaryMorph)!)
        : null;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        
        final double titleExpandedTop = h * 0.15;
        final double titleCompactTop = (h - titleFontSize) / 2 - 2;
        final double titleTop = lerpDouble(titleExpandedTop, titleCompactTop, primaryMorph)!;
        
        final double balanceExpandedTop = titleExpandedTop + titleFontSize + 8;
        final double balanceCompactTop = (h - balanceFontSize) / 2 - 2;
        final double balanceTop = lerpDouble(balanceExpandedTop, balanceCompactTop, primaryMorph)!;
        
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
                  vaultName,
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
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Divider(
                          height: 1, 
                          thickness: 0.5, 
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
                        ),
                      ),

                      SizedBox(
                        height: 40,
                        child: hasFlexibleTx 
                          ? _buildRangeStats(txs)
                          : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 12),
                      const Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.grey),
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
