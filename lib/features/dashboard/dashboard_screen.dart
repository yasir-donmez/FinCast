import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_constants.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/providers/db_providers.dart';
import '../../shared/widgets/precision_surface.dart';
import 'dashboard_providers.dart';
import '../../core/providers/settings_provider.dart';
import 'widgets/rotary_time_dial.dart';
import 'widgets/precision_vault_grid.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final dashboardItems = ref.watch(dashboardItemsProvider);
    final totalBalance = ref.watch(displayBalanceProvider);
    final bonus = ref.watch(simulationBonusProvider);
    final minBalance = ref.watch(netMinBalanceProvider) + bonus;
    final maxBalance = ref.watch(netMaxBalanceProvider) + bonus;

    final bool hasFlexibleRange = minBalance != totalBalance || maxBalance != totalBalance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = ref.watch(rotaryColorProvider);

    return Stack(
      children: [
        // Dinamik Organik Arka Plan
        if (isDark) ...[
          Positioned(
            top: -100,
            right: -50,
            child: _PrecisionBlob(
              color: activeColor.withValues(alpha: 0.15),
              size: 300,
            ),
          ),
          Positioned(
            bottom: 200,
            left: -100,
            child: _PrecisionBlob(
              color: AppColors.getSecondary(context).withValues(alpha: 0.1),
              size: 400,
            ),
          ),
        ],
        
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Bileşenleri ekran geneline yay
              children: [
                const SizedBox(height: AppSizes.paddingSmall),
                
                // 1. Kasalar Alanı: Expanded flex ile alan yönetilir
                Expanded(
                  flex: 40, 
                  child: PrecisionVaultGrid(items: dashboardItems),
                ),
                
                const Spacer(flex: 2), // Nefes payı geri alındı (Flex: 2)

                // 2. Bakiye Alanı
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
                  child: AnimatedCurrencySelector(
                    fontSize: 28, // Font boyutu geri alındı
                    totalBalance: totalBalance,
                    minBalance: hasFlexibleRange ? minBalance : null,
                    maxBalance: hasFlexibleRange ? maxBalance : null,
                  ),
                ),
                
                const Spacer(flex: 2), // Nefes payı geri alındı (Flex: 2)

                // 3. Zaman Kadranı: FittedBox ile ferah bir yerleşim
                Expanded(
                  flex: 48,
                  child: Align(
                    alignment: Alignment.topCenter, // Ortalamak yerine en üste yasla
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: const RotaryTimeDial(),
                      ),
                    ),
                  ),
                ),
                
                // 4. Alt Boşluk: Navigasyon barı için dinamik ama ferah pay
                const Spacer(flex: 8), 
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Reklam alanı kaldırıldı.
}

/// Arka planda süzülen sıvımsı renk kütlesi
class _PrecisionBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _PrecisionBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class AnimatedCurrencySelector extends ConsumerWidget {
  final double fontSize;
  final double totalBalance;
  final double? minBalance;
  final double? maxBalance;

  const AnimatedCurrencySelector({
    super.key,
    this.fontSize = 24,
    required this.totalBalance,
    this.minBalance,
    this.maxBalance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rotaryColor = ref.watch(rotaryColorProvider);
    final activeColor = isDark ? rotaryColor : AppColors.getAccentDeep(context, rotaryColor);
    final currencySymbol = ref.watch(settingsProvider.select((s) => s.currencySymbol));

    return Container(
      height: 106,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sol: Para Birimi Simgesi (Sabit Boyut)
          PrecisionSurface(
            width: 54,
            height: 54,
            padding: EdgeInsets.zero,
            borderRadius: 27,
            isGlass: true,
            blur: 15,
            child: Center(
              child: Text(
                currencySymbol,
                style: TextStyle(
                  color: activeColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Sağ: Tutar + Min/Max
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        CurrencyUtils.formatFullAmount(totalBalance),
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2.5,
                          shadows: isDark ? [
                            Shadow(color: activeColor.withValues(alpha: 0.6), blurRadius: 20),
                          ] : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppCurrency.getCode(currencySymbol),
                        style: TextStyle(
                          color: activeColor.withValues(alpha: isDark ? 0.35 : 0.55),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (minBalance != null && maxBalance != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          _buildRangeIndicator(
                            context: context,
                            icon: Icons.south_east_rounded,
                            amount: minBalance!,
                            color: AppColors.getExpense(context),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: activeColor.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildRangeIndicator(
                            context: context,
                            icon: Icons.north_east_rounded,
                            amount: maxBalance!,
                            color: AppColors.getIncome(context),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeIndicator({required BuildContext context, required IconData icon, required double amount, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(
          CurrencyUtils.formatAmount(amount),
          style: TextStyle(
            color: color.withValues(alpha: isDark ? 0.9 : 1.0), // Aydınlıkta tam opak
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
