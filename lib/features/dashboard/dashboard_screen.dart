import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_constants.dart';
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
    // Riverpod'dan verileri çekiyoruz (Kasa/Grup + Tekil İşlemler)
    final dashboardItems = ref.watch(dashboardItemsProvider);
    final totalBalance = ref.watch(displayBalanceProvider);

    final bonus = ref.watch(simulationBonusProvider);
    final minBalance = ref.watch(netMinBalanceProvider) + bonus;
    final maxBalance = ref.watch(netMaxBalanceProvider) + bonus;

    final bool hasFlexibleRange =
        minBalance != totalBalance || maxBalance != totalBalance;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSizes.paddingLarge),

          // 1. ÜST BÖLÜM: Dinamik Kasa (Vault) Kartları (Yatay Scroll, 2 Satır)
          // Sabit yükseklik verilerek alt bileşenlerin kasa yokken yukarı zıplaması engelleniyor.
          SizedBox(
            height: 250,
            child: ExpandableVaultGrid(items: dashboardItems),
          ),

          const SizedBox(height: AppSizes.paddingLarge),

          // 2. ORTA BÖLÜM: Devasa Ana Bakiye ve Toplam Servet Göstergesi
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLarge,
            ),
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

          // 3. ALT BÖLÜM: Zaman Makinesi (Rotary Dial)
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
  ConsumerState<AnimatedCurrencySelector> createState() =>
      _AnimatedCurrencySelectorState();
}

class _AnimatedCurrencySelectorState
    extends ConsumerState<AnimatedCurrencySelector> {
  final List<String> _currencies = ['₺', '\$', '€', '£'];
  int _currentIndex = 0;
  final GlobalKey _selectorKey = GlobalKey();

  void _showCurrencyPicker(BuildContext context) {
    HapticFeedback.lightImpact();

    // Widget'in ekrandaki konumunu bul
    final RenderBox? renderBox =
        _selectorKey.currentContext?.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = renderBox?.size ?? Size.zero;

    // Kesintisiz scroll hesaplaması için özel denetleyici oluşturuyoruz
    final scrollController = FixedExtentScrollController(
      initialItem: 500 * _currencies.length + _currentIndex,
    );

    // Tam Ekran Odaklanmış Görünüm (Blur + Orijinal Konumda Çark)
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Kapat',
      barrierColor: Colors.black.withOpacity(
        0.85,
      ), // Neredeyse tamamen karanlık katman
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ColorFilter.mode(
            Colors.black.withOpacity(0.3), // Ekstra blur/karartma
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
                  // Arka planı tıklandığında popup'ı kapatan alan ve kaydırmayı dinleyen alan
                  Positioned.fill(
                    child: RawGestureDetector(
                      behavior: HitTestBehavior.translucent,
                      gestures: {
                        TapGestureRecognizer:
                            GestureRecognizerFactoryWithHandlers<
                              TapGestureRecognizer
                            >(
                              () => TapGestureRecognizer(),
                              (instance) =>
                                  instance.onTap = () =>
                                      Navigator.of(context).pop(),
                            ),
                        VerticalDragGestureRecognizer:
                            GestureRecognizerFactoryWithHandlers<
                              VerticalDragGestureRecognizer
                            >(() => VerticalDragGestureRecognizer(), (
                              instance,
                            ) {
                              Drag? drag;
                              instance
                                ..onDown = (details) {
                                  if (scrollController.hasClients) {
                                    drag = scrollController.position.drag(
                                      DragStartDetails(
                                        globalPosition: details.globalPosition,
                                        localPosition: details.localPosition,
                                      ),
                                      () {
                                        drag = null;
                                      },
                                    );
                                  }
                                }
                                ..onUpdate = (details) {
                                  drag?.update(details);
                                }
                                ..onEnd = (details) {
                                  drag?.end(details);
                                }
                                ..onCancel = () {
                                  drag?.cancel();
                                };
                            }),
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  // Çarkın tam orijinal widget'ın olduğu yerde çıkması sağlanıyor
                  Positioned(
                    // Y ekseninde çarkı tam ortalayacak şekilde yukarı kaydırıyoruz
                    top: offset.dy - (250 - size.height / 2),
                    // X ekseninde çarkı kendi ortasından hizalamaya çalışıyoruz
                    left: offset.dx - (100 - size.width) / 2,
                    child: Material(
                      type: MaterialType.transparency,
                      child: GestureDetector(
                        onTap: () {}, // İçeriğe tıklamayı yutması için
                        child: Container(
                          width: 100, // Daha ince çark genişliği
                          height:
                              500, // Kavisle kaybolması için alan (artırıldı)
                          color: Colors.transparent,
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (_) => false, // Sürekli dinliyoruz
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Center selection box (grey background like iOS picker)
                                Container(
                                  height: 42,
                                  width:
                                      70, // Daha uygun bir boyut (kutuyu küçülttük)
                                  decoration: BoxDecoration(
                                    color: ref
                                        .read(rotaryColorProvider)
                                        .withOpacity(0.12), // Dinamik renk
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
                                      _currentIndex =
                                          index % _currencies.length;
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    builder: (context, index) {
                                      final currency =
                                          _currencies[index %
                                              _currencies.length];

                                      return AnimatedBuilder(
                                        animation: scrollController,
                                        builder: (context, child) {
                                          double distance = 0.0;
                                          if (scrollController.hasClients) {
                                            final currentPosition =
                                                scrollController.offset / 48.0;
                                            distance = (currentPosition - index)
                                                .abs();
                                          } else {
                                            final initialPosition =
                                                (500 * _currencies.length +
                                                        _currentIndex)
                                                    .toDouble();
                                            distance = (initialPosition - index)
                                                .abs();
                                          }

                                          // Smooth opacity and size transitions to prevent jittering
                                          final double clampedDistance =
                                              distance.clamp(0.0, 1.0);
                                          final double dynamicOpacity =
                                              (1.0 - (clampedDistance * 0.6))
                                                  .clamp(0.3, 1.0);

                                          // Pürüzsüz boyut geçişi (titremeyi engeller)
                                          final double dynamicFontSize =
                                              34.0 -
                                              (clampedDistance *
                                                  6.0); // 34 ile 28 arası kesintisiz kayar

                                          final bool isCenter =
                                              distance <
                                              0.15; // Sadece tam yuvaya oturduğunda vurgu yap

                                          return Container(
                                            alignment: Alignment.center,
                                            child: Opacity(
                                              opacity: dynamicOpacity,
                                              child: Text(
                                                currency,
                                                style: TextStyle(
                                                  color: isCenter
                                                      ? ref.read(
                                                          rotaryColorProvider,
                                                        )
                                                      : ref
                                                            .read(
                                                              rotaryColorProvider,
                                                            )
                                                            .withOpacity(0.6),
                                                  fontSize: dynamicFontSize,
                                                  fontWeight: FontWeight
                                                      .w600, // Kalınlık değişimi titremeye yol açar, sabitlendi
                                                  shadows: isCenter
                                                      ? [
                                                          Shadow(
                                                            color: ref
                                                                .read(
                                                                  rotaryColorProvider,
                                                                )
                                                                .withOpacity(
                                                                  0.8,
                                                                ),
                                                            blurRadius: 10,
                                                          ),
                                                        ]
                                                      : null, // Sadece yuvaya oturan parlasın
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
      case '₺':
        return 'TL';
      case '\$':
        return 'USD';
      case '€':
        return 'EUR';
      case '£':
        return 'GBP';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Seçili tematik rengi Riverpod'dan alıyoruz
    final activeColor = ref.watch(rotaryColorProvider);

    return GestureDetector(
      onLongPress: () => _showCurrencyPicker(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            key:
                _selectorKey, // Konum tespiti için key doğrudan bu elemente atandı
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              boxShadow: const [
                BoxShadow(
                  color: AppColors.darkShadow,
                  offset: Offset(5, 5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: AppColors.lightShadow,
                  offset: Offset(-5, -5),
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
          // Bakiye ve Para Birimi Etiketi (Taşma yapmaması için Expanded + FittedBox)
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 65,
              ), // Limitler varsa biraz daha yüksek
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
                          widget.totalBalance.toStringAsFixed(2),
                          style: TextStyle(
                            color: activeColor, // Dinamik iOS premium rengi
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.5,
                            shadows: [
                              Shadow(
                                color: activeColor,
                                blurRadius: 15, // Glow Efekti
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width:
                              70, // Sabit genişlik 50'den 70'e çıkarıldı: "USD", "EUR" gibi 3 harflilerin sığması ve alt satıra inmemesi için
                          child: Text(
                            _getCurrencyCode(_currencies[_currentIndex]),
                            style: TextStyle(
                              color: activeColor.withOpacity(0.8),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: activeColor.withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
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
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 14,
                            color: const Color(0xFFE57373),
                          ),
                          Text(
                            widget.minBalance!.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFFE57373),
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '  ~  ',
                            style: TextStyle(
                              fontSize: 16,
                              color: activeColor.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 14,
                            color: Colors.greenAccent,
                          ),
                          Text(
                            widget.maxBalance!.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
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
