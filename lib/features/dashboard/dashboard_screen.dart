import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_constants.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/providers/db_providers.dart';
import 'dashboard_providers.dart';
import 'widgets/rotary_time_dial.dart';
import 'widgets/expandable_vault_grid.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

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

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSizes.paddingLarge),
          SizedBox(
            height: 250,
            child: ExpandableVaultGrid(items: dashboardItems),
          ),
          const SizedBox(height: AppSizes.paddingLarge),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
            child: Column(
              children: [
                AnimatedCurrencySelector(
                  fontSize: 28,
                  totalBalance: totalBalance,
                  minBalance: hasFlexibleRange ? minBalance : null,
                  maxBalance: hasFlexibleRange ? maxBalance : null,
                ),
              ],
            ),
          ),
          const Spacer(flex: 1),
          const Center(child: RotaryTimeDial()),
          const Spacer(flex: 2),
        ],
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
  final List<String> _currencies = ['₺', '\$', '€', '£'];
  int _currentIndex = 0;
  final GlobalKey _selectorKey = GlobalKey();

  void _showCurrencyPicker(BuildContext context) {
    HapticFeedback.lightImpact();
    final RenderBox? renderBox = _selectorKey.currentContext?.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = renderBox?.size ?? Size.zero;

    final scrollController = FixedExtentScrollController(
      initialItem: 500 * _currencies.length + _currentIndex,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.close,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.3),
            BlendMode.darken,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: FadeTransition(
              opacity: animation,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RawGestureDetector(
                      behavior: HitTestBehavior.translucent,
                      gestures: {
                        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                          () => TapGestureRecognizer(),
                          (instance) => instance.onTap = () => Navigator.of(context).pop(),
                        ),
                        VerticalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
                          () => VerticalDragGestureRecognizer(),
                          (instance) => instance.onDown = (details) {
                            if (scrollController.hasClients) {
                              scrollController.position.drag(DragStartDetails(globalPosition: details.globalPosition, localPosition: details.localPosition), () {});
                            }
                          },
                        ),
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Positioned(
                    top: offset.dy - (250 - size.height / 2),
                    left: offset.dx - (100 - size.width) / 2,
                    child: Material(
                      type: MaterialType.transparency,
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 100,
                          height: 500,
                          color: Colors.transparent,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 42,
                                width: 70,
                                decoration: BoxDecoration(
                                  color: ref.read(rotaryColorProvider).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              ListWheelScrollView.useDelegate(
                                controller: scrollController,
                                itemExtent: 48.0,
                                diameterRatio: 1.2,
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
                                          final currentPosition = scrollController.offset / 48.0;
                                          distance = (currentPosition - index).abs();
                                        } else {
                                          final initialPosition = (500 * _currencies.length + _currentIndex).toDouble();
                                          distance = (initialPosition - index).abs();
                                        }
                                        final double clampedDistance = distance.clamp(0.0, 1.0);
                                        final double dynamicOpacity = (1.0 - (clampedDistance * 0.6)).clamp(0.3, 1.0);
                                        final double dynamicFontSize = 34.0 - (clampedDistance * 6.0);
                                        final bool isCenter = distance < 0.15;

                                        return Container(
                                          alignment: Alignment.center,
                                          child: Opacity(
                                            opacity: dynamicOpacity,
                                            child: Text(
                                              currency,
                                              style: TextStyle(
                                                color: isCenter ? ref.read(rotaryColorProvider) : ref.read(rotaryColorProvider).withValues(alpha: 0.6),
                                                fontSize: dynamicFontSize,
                                                fontWeight: FontWeight.w600,
                                                shadows: isCenter ? [Shadow(color: ref.read(rotaryColorProvider).withValues(alpha: 0.8), blurRadius: 10)] : null,
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getCurrencyCode(String symbol) {
    switch (symbol) {
      case '₺': return 'TL';
      case '\$': return 'USD';
      case '€': return 'EUR';
      case '£': return 'GBP';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = ref.watch(rotaryColorProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () => _showCurrencyPicker(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            key: _selectorKey,
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.getSurface(context),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getDarkShadow(context).withValues(alpha: isDark ? 1.0 : 0.4),
                  offset: const Offset(5, 5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: AppColors.getLightShadow(context).withValues(alpha: isDark ? 0.1 : 1.0),
                  offset: const Offset(-5, -5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              _currencies[_currentIndex],
              style: TextStyle(
                color: activeColor,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: activeColor, blurRadius: 10)],
              ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 95),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          CurrencyUtils.formatFullAmount(widget.totalBalance),
                          style: TextStyle(
                            color: activeColor,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.5,
                            shadows: [Shadow(color: activeColor, blurRadius: 15)],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getCurrencyCode(_currencies[_currentIndex]),
                          style: TextStyle(
                            color: activeColor.withValues(alpha: 0.8),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: activeColor.withValues(alpha: 0.5), blurRadius: 10)],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (widget.minBalance != null && widget.maxBalance != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.getExpense(context)),
                          Text(
                            CurrencyUtils.formatAmount(widget.minBalance!),
                            style: TextStyle(color: AppColors.getExpense(context), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text('~', style: TextStyle(color: AppColors.getTextSecondary(context).withValues(alpha: 0.5), fontSize: 12)),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_upward_rounded, size: 14, color: activeColor),
                          const SizedBox(width: 4),
                          Text(
                            CurrencyUtils.formatAmount(widget.maxBalance!),
                            style: TextStyle(color: activeColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
