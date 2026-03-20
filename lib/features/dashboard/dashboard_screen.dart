import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_constants.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/providers/db_providers.dart';
import '../../shared/widgets/fluid_container.dart';
import '../../shared/widgets/fluid_sheet.dart';
import 'dashboard_providers.dart';
import 'widgets/rotary_time_dial.dart';
import 'widgets/expandable_vault_grid.dart';
import 'package:flutter/services.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardItems = ref.watch(dashboardItemsProvider);
    final totalBalance = ref.watch(displayBalanceProvider);

    final bonus = ref.watch(simulationBonusProvider);
    final minBalance = ref.watch(netMinBalanceProvider) + bonus;
    final maxBalance = ref.watch(netMaxBalanceProvider) + bonus;

    final bool hasFlexibleRange = minBalance != totalBalance || maxBalance != totalBalance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = ref.watch(rotaryColorProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: Stack(
        children: [
          // YENİ: Dinamik Organik Arka Plan (Sıvı Kütleler)
          if (isDark) ...[
            Positioned(
              top: -100,
              right: -50,
              child: _LiquidBlob(
                color: activeColor.withValues(alpha: 0.15),
                size: 300,
              ),
            ),
            Positioned(
              bottom: 200,
              left: -100,
              child: _LiquidBlob(
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
                children: [
                  const SizedBox(height: AppSizes.paddingSmall),
                  // Kasalar Alanı - ShaderMask sadece liste içeriğine uygulanır
                  SizedBox(
                    height: 310, // 290 -> 310: Daha ferah (Airy) bir görünüm için artırıldı
                    child: ExpandableVaultGrid(items: dashboardItems),
                  ),
                  const SizedBox(height: 4),
                  // Bakiye Alanı
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
                    child: AnimatedCurrencySelector(
                      fontSize: 28,
                      totalBalance: totalBalance,
                      minBalance: hasFlexibleRange ? minBalance : null,
                      maxBalance: hasFlexibleRange ? maxBalance : null,
                    ),
                  ),
                  const Spacer(flex: 1), 
                  const Center(child: RotaryTimeDial()),
                  const SizedBox(height: 60), // Alt boşluk 40'tan 60'a çıkarıldı
                  const Spacer(flex: 2), // Alt flex dengesi yukarı itecek şekilde artırıldı
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}

/// Arka planda süzülen sıvımsı renk kütlesi
class _LiquidBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _LiquidBlob({required this.color, required this.size});

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

class AnimatedCurrencySelector extends ConsumerStatefulWidget {
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
  ConsumerState<AnimatedCurrencySelector> createState() => _AnimatedCurrencySelectorState();
}

class _AnimatedCurrencySelectorState extends ConsumerState<AnimatedCurrencySelector> {
  final List<String> _currencies = AppCurrency.supportedSymbols;
  int _currentIndex = 0;

  void _showCurrencyPicker(BuildContext context) {
    HapticFeedback.lightImpact();
    
    final scrollController = FixedExtentScrollController(
      initialItem: 500 * _currencies.length + _currentIndex,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rotaryColor = ref.read(rotaryColorProvider);
    final activeColor = isDark ? rotaryColor : AppColors.getAccentDeep(context, rotaryColor);

    FluidSheet.show(
      context: context,
      title: AppLocalizations.of(context)!.selectCurrency,
      height: 400,
      child: Center(
        child: SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Seçim Belirteci (Highlight)
              FluidContainer(
                width: 80,
                height: 50,
                padding: EdgeInsets.zero,
                borderRadius: 15,
                isGlass: true,
                color: ref.read(rotaryColorProvider).withValues(alpha: 0.1),
                child: const SizedBox.shrink(),
              ),
              ListWheelScrollView.useDelegate(
                controller: scrollController,
                itemExtent: 60.0,
                diameterRatio: 1.5,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (int index) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _currentIndex = index % _currencies.length;
                  });
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    final currency = _currencies[index % _currencies.length];
                    return AnimatedBuilder(
                      animation: scrollController,
                      builder: (context, child) {
                        double distance = 0.0;
                        if (scrollController.hasClients) {
                          final currentPosition = scrollController.offset / 60.0;
                          distance = (currentPosition - index).abs();
                        }
                        final double clampedDistance = distance.clamp(0.0, 1.0);
                        final double dynamicOpacity = (1.0 - (clampedDistance * 0.7)).clamp(0.2, 1.0);
                        final double dynamicFontSize = 38.0 - (clampedDistance * 10.0);
                        final bool isCenter = distance < 0.2;

                        return Center(
                          child: Opacity(
                            opacity: dynamicOpacity,
                            child: Text(
                              currency,
                              style: TextStyle(
                                color: isCenter 
                                  ? activeColor 
                                  : activeColor.withValues(alpha: isDark ? 0.4 : 0.65), // Aydınlıkta opacity artırıldı (0.4 -> 0.65)
                                fontSize: dynamicFontSize,
                                fontWeight: FontWeight.w800,
                                shadows: isCenter ? [
                                  Shadow(color: activeColor.withValues(alpha: isDark ? 0.5 : 0.3), blurRadius: 15)
                                ] : null,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrencyCode(String symbol) => AppCurrency.getCode(symbol);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rotaryColor = ref.watch(rotaryColorProvider);
    final activeColor = isDark ? rotaryColor : AppColors.getAccentDeep(context, rotaryColor);

    return GestureDetector(
      onLongPress: () => _showCurrencyPicker(context),
      child: Container(
        height: 120, // Sabit yükseklik
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Dikeyde merkezleyerek en dengeli görünümü sağla
          children: [
            // Sol: Para Birimi Simgesi (Sabit Boyut)
            FluidContainer(
              width: 54,
              height: 54,
              padding: EdgeInsets.zero,
              borderRadius: 27,
              isGlass: true,
              blur: 15,
              child: Center(
                child: Text(
                  _currencies[_currentIndex],
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    shadows: isDark ? [
                      Shadow(color: activeColor.withValues(alpha: 0.6), blurRadius: 10),
                    ] : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Sağ: Tutar + Min/Max (Dikey kolon içinde birbirine göre ORTALANIR)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, // Min/Max tutarın tam altında merkezlenir
                mainAxisAlignment: MainAxisAlignment.center,
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
                          CurrencyUtils.formatFullAmount(widget.totalBalance),
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
                          _getCurrencyCode(_currencies[_currentIndex]),
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
                  if (widget.minBalance != null && widget.maxBalance != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2), // Sadece üst boşluk, yatayda ortalanacak
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            _buildRangeIndicator(
                              context: context,
                              icon: Icons.south_east_rounded,
                              amount: widget.minBalance!,
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
                              amount: widget.maxBalance!,
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
