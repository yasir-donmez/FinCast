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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // --- Curves for different effects ---
    final double widthT = Curves.easeOutQuart.transform(morphProgress);
    
    final double cardWidth = lerpDouble(screenWidth * 0.70, screenWidth, widthT)!;
    final double cardHeight = lerpDouble(280, 56, morphProgress)!;
    
    // --- Glass Morphing Spread (2. Madde) ---
    final double decorationOpacity = (1 - morphProgress * 2.2).clamp(0.0, 1.0); 
    final double cardRadius = lerpDouble(32, 0, Curves.easeInOutCubic.transform((morphProgress * 1.8).clamp(0.0, 1.0)))!;
    
    final double hPad = lerpDouble(24, 20, morphProgress)!;
    final double effectiveWidth = isCurrent ? cardWidth : screenWidth * 0.70;
    
    return OverflowBox(
      maxWidth: effectiveWidth,
      maxHeight: cardHeight,
      child: Container(
        width: effectiveWidth,
        height: cardHeight,
        // Dış gölgeyi (boxShadow) tamamen kaldırdık, yandakilerle aynı oldu
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // === DEKORASYON KATMANI (Cam Etkisi Transferi) ===
            if (decorationOpacity > 0.01)
              Positioned.fill(
                child: Opacity(
                  opacity: decorationOpacity,
                  child: FluidContainer(
                    isGlass: false,
                    isConvex: true, 
                    borderRadius: cardRadius,
                    borderColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                    color: AppColors.getSurface(context).withValues(alpha: isCurrent ? 1.0 : 0.5),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            
            // === İÇERİK KATMANI ===
            Positioned(
              left: hPad, right: hPad,
              top: 0, bottom: 0,
              child: _buildMorphContent(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMorphContent(BuildContext context, bool isDark) {
    final hasFlexibleTx = txs.any((t) => t.minAmount != null || t.maxAmount != null);
    
    // Animasyon progressleri
    final double contentT = Curves.easeInOutCubic.transform((morphProgress * 1.2).clamp(0.0, 1.0));
    final double magneticT = Curves.easeOutBack.transform(morphProgress);
    
    final double titleFontSize = lerpDouble(11, 17, contentT)!;
    final double balanceFontSize = lerpDouble(42, 16, contentT)!;
    final double titleLetterSpacing = lerpDouble(1.8, -0.4, contentT)!;
    final double balanceLetterSpacing = lerpDouble(-2.5, 0.2, contentT)!;
    
    final double badgePadH = lerpDouble(0, 14, contentT)!;
    final double badgePadV = lerpDouble(0, 6, contentT)!;
    final double badgeBgAlpha = contentT * (isDark ? 0.15 : 0.08);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        
        // --- Geniş Mod (Expanded) Pozisyonları ---
        final double titleExpandedTop = h * 0.12;
        final double balanceExpandedTop = titleExpandedTop + 30;
        final double secondaryExpandedTop = balanceExpandedTop + 60;
        
        // --- Dar Mod (Compact) Pozisyonları ---
        final double titleCompactTop = (h - titleFontSize) / 2;
        final double balanceCompactTop = (h - balanceFontSize) / 2;

        final double titleTop = lerpDouble(titleExpandedTop, titleCompactTop, magneticT)!;
        final double balanceTop = lerpDouble(balanceExpandedTop, balanceCompactTop, magneticT)!;
        
        final double secondaryOpacity = (1 - morphProgress * 4.5).clamp(0.0, 1.0);
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // === TITLE ===
            Positioned(
              left: 0, right: 0,
              top: titleTop,
              child: Align(
                alignment: Alignment.lerp(Alignment.center, Alignment.centerLeft, magneticT)!,
                child: Text(
                  vaultName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: titleLetterSpacing,
                    color: contentT > 0.8 ? null : activeColor.withValues(alpha: lerpDouble(0.8, 1.0, contentT)!),
                  ),
                ),
              ),
            ),
            
            // === BALANCE ===
            Positioned(
              left: 0, right: 0,
              top: balanceTop,
              child: Align(
                alignment: Alignment.lerp(Alignment.center, Alignment.centerRight, magneticT)!,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: badgePadH, vertical: badgePadV),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: badgeBgAlpha),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    contentT > 0.6
                      ? '₺${CurrencyUtils.formatAmount(balance)}'
                      : '₺${CurrencyUtils.formatFullAmount(balance)}',
                    style: TextStyle(
                      fontSize: balanceFontSize,
                      fontWeight: FontWeight.w900,
                      color: activeColor,
                      letterSpacing: balanceLetterSpacing,
                    ),
                  ),
                ),
              ),
            ),
            
            // === SECONDARY STATS (ORİJİNAL DİKEY DÜZEN) ===
            if (secondaryOpacity > 0.01)
              Positioned(
                left: 0, right: 0,
                top: secondaryExpandedTop,
                child: Opacity(
                  opacity: secondaryOpacity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildMiniStat(l10n.income, income, AppColors.getIncome(context))),
                          Container(width: 1, height: 30, color: activeColor.withValues(alpha: 0.15)),
                          Expanded(child: _buildMiniStat(l10n.expense, expense, AppColors.getExpense(context))),
                        ],
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Divider(
                          height: 1, 
                          thickness: 0.5, 
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)
                        ),
                      ),

                      if (hasFlexibleTx) ...[
                        _buildRangeStats(txs),
                        const SizedBox(height: 16),
                      ],

                      const Icon(Icons.swap_horiz_rounded, size: 20, color: Colors.grey),
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
