import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_constants.dart';
import '../dashboard_providers.dart';

/// FinCast'in "Zaman Makinesi" vizyonu olan Rotary Dial (Fiziksel Kadran)
/// Progressive Time Scale (Giderek Hızlanan Zaman) mekanizması ile birleşti.
class RotaryTimeDial extends ConsumerStatefulWidget {
  const RotaryTimeDial({super.key});

  @override
  ConsumerState<RotaryTimeDial> createState() => _RotaryTimeDialState();
}

class _RotaryTimeDialState extends ConsumerState<RotaryTimeDial> {
  double _currentAngle = 0.0;
  double _lastAngle = 0.0;
  int _lastHapticLevel = 0;

  void _onPanStart(DragStartDetails details, Size widgetSize) {
    HapticFeedback.lightImpact();
    final center = Offset(widgetSize.width / 2, widgetSize.height / 2);
    _lastAngle = atan2(
      details.localPosition.dy - center.dy,
      details.localPosition.dx - center.dx,
    );
  }

  void _onPanUpdate(DragUpdateDetails details, Size widgetSize) {
    final center = Offset(widgetSize.width / 2, widgetSize.height / 2);
    final touchPosition = details.localPosition;

    final angle = atan2(
      touchPosition.dy - center.dy,
      touchPosition.dx - center.dx,
    );

    setState(() {
      var delta = angle - _lastAngle;
      // Handle wrap-around
      if (delta > pi) {
        delta -= 2 * pi;
      } else if (delta < -pi) {
        delta += 2 * pi;
      }

      _lastAngle = angle;
      _currentAngle += delta;

      // Geleceğe yatırım yapıyoruz, eksik zamana düşmesine (negatif) izin verme
      if (_currentAngle < 0) {
        _currentAngle = 0;
      }

      // Dinamik Rengi Hesapla ve Global Olarak Bildir
      double turns = _currentAngle / (2 * pi);
      final activeColor = _getSmoothColor(turns);
      
      // SADECE renk değiştiğinde güncelle (Gereksiz rebuild'leri önle)
      if (ref.read(rotaryColorProvider) != activeColor) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(rotaryColorProvider.notifier).state = activeColor;
        });
      }

      // Haptic feedback every tick (40 ticks per turn)
      int currentTick = (_currentAngle / (2 * pi / 40)).floor();
      if (currentTick != _lastHapticLevel) {
        _lastHapticLevel = currentTick;
        HapticFeedback.selectionClick();

        // SİMÜLASYON Olarak Bakiyeyi artır: Her tikte belirli bir ivme ile para kazanılmış gibi
        // Gerçek bakiyeyi bozmadan, üzerine eklenecek "Sanal Gelecek Bakiyesi" güncelleniyor.
        final extraMultiplier = (pow(_currentAngle, 1.5) * 800)
            .toDouble(); // Geleceğe gittikçe ivme artar
        ref.read(simulationBonusProvider.notifier).state = extraMultiplier;
      }
    });
  }

  Color _getSmoothColor(double turns) {
    // 0 -> 1 Tur (Mavi'den Yeşile) yumuşak geçiş
    if (turns <= 1.0) {
      return Color.lerp(
            AppColors.primary,
            const Color(0xFF34C759),
            turns, // 0'dan 1'e kadar yavaşça
          ) ??
          AppColors.primary;
    }

    // 1 Turu (360 dereceyi) geçtikten sonra TÜM renkler döngüye girer.
    // Her turda tüm RGB spektrumu baştan sona hızlıca ve sürekli dönmeye başlar.
    final List<Color> rainbow = [
      const Color(0xFF34C759), // iOS Yeşil
      const Color(0xFFFFCC00), // iOS Sarı
      const Color(0xFFFF9500), // iOS Turuncu
      const Color(0xFFFF2D55), // iOS Pembe/Kırmızı
      const Color(0xFFAF52DE), // iOS Mor
      AppColors.primary, // Mavi/Cyan
      const Color(0xFF34C759), // Tekrar Yeşile dön (Kusursuz Gökkuşağı Döngüsü)
    ];

    // İlk turdan sonraki kısmı al, böylece her tam tur (1.0, 2.0...) 0'a denk gelir, gökkuşağı kendini tekrar eder
    double progress = (turns - 1.0) % 1.0;
    progress = progress * (rainbow.length - 1);

    int lower = progress.floor().clamp(0, rainbow.length - 2);
    int upper = lower + 1;
    double fraction = progress - lower;

    return Color.lerp(rainbow[lower], rainbow[upper], fraction) ??
        rainbow.first;
  }

  String _getTimeLabel(double currentAngle) {
    if (currentAngle <= 0.01) return "Bugün";
    double turns = currentAngle / (2 * pi);

    if (turns <= 1.0) {
      // 1. Tur: 0 - 7 Gün
      int days = (turns * 7).round();
      if (days == 0) return "Bugün";
      return "$days Gün";
    } else if (turns <= 2.0) {
      // 2. Tur: 1 - 4 Hafta
      double fraction = turns - 1.0;
      int weeks = 1 + (fraction * 3).round();
      if (weeks >= 4) return "1 Ay";
      return "$weeks Hafta";
    } else if (turns <= 3.0) {
      // 3. Tur: 1 - 12 Ay (720 -> 1080 derece)
      double fraction = turns - 2.0;
      int months = 1 + (fraction * 11).round();
      if (months >= 12) return "1 Yıl";
      return "$months Ay";
    } else {
      // 4. Tur ve sonrası: Yıllar (1080+ derece)
      double fraction = turns - 3.0;
      int years = 1 + (fraction * 9).round();
      return "$years Yıl";
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = _getTimeLabel(_currentAngle);
    final activeColor = _getSmoothColor(_currentAngle / (2 * pi));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ZAMAN ETİKETİ (Dial'ın Hemen Üstünde)
        Column(
          children: [
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, -0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                timeLabel,
                key: ValueKey(timeLabel),
                style: TextStyle(
                  color: activeColor, // Işıltılı ve Değişen Renk
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  shadows: [
                    Shadow(color: activeColor.withValues(alpha: 0.8), blurRadius: 10),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSizes.paddingXLarge * 1.5),

        // DIAL KISMI (Maksimum Boyut Kısıtlaması Eklenerek Taşma Önlendi)
        LayoutBuilder(
          builder: (context, constraints) {
            // Alanın yüksekliği veya genişliğine göre en güvenli kısıtlamayı al
            final safeSize = min(constraints.maxWidth, constraints.maxHeight);
            final size = min(safeSize, 240.0); // 260'ı 240'a indirdik
            final knobSize = size * 0.65;

            return GestureDetector(
              onPanUpdate: (details) => _onPanUpdate(details, Size(size, size)),
              onPanStart: (details) => _onPanStart(details, Size(size, size)),
              onDoubleTap: () {
                HapticFeedback.heavyImpact();
                setState(() {
                  _currentAngle = 0.0;
                  _lastAngle = 0.0;
                  ref.read(simulationBonusProvider.notifier).state = 0.0;
                });
              },
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Çentikler (Animasyonlu ve Katmanlı)
                    SizedBox(
                      width: size,
                      height: size,
                      child: CustomPaint(
                        painter: _DialTicksPainter(
                          currentAngle: _currentAngle,
                          tickCount: 40,
                          activeColor:
                              activeColor, // Renk paletini paint'e taşıyoruz
                        ),
                      ),
                    ),

                    // Fiziksel Çevirme Topuzu (Knob)
                    Transform.rotate(
                      angle:
                          _currentAngle -
                          pi /
                              2, // Sıfır noktasını en tepeye (-90 derece) hizala
                      child: Container(
                        width: knobSize,
                        height: knobSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.getSurface(context),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.getDarkShadow(context).withValues(alpha: 0.4),
                              offset: const Offset(15, 15),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: AppColors.getLightShadow(context).withValues(alpha: 0.8),
                              offset: const Offset(-8, -8),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              offset: const Offset(4, 4),
                              blurRadius: 10,
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Çukur Leke Göstergesi
                            Align(
                              alignment: const Alignment(0.7, 0.0),
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.getDarkShadow(context).withValues(alpha: 0.3),
                                      width: 1.0,
                                    ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.getDarkShadow(context).withValues(alpha: 0.5),
                                      AppColors.getInnerSurface(context),
                                      AppColors.getLightShadow(context).withValues(alpha: 0.05),
                                    ],
                                    stops: const [0.0, 0.4, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DialTicksPainter extends CustomPainter {
  final double currentAngle;
  final int tickCount;
  final Color activeColor;

  _DialTicksPainter({
    required this.currentAngle,
    required this.tickCount,
    required this.activeColor,
  });

  // Pre-allocated Paint objects to prevent OOM
  final Paint _tickPaint = Paint()..strokeCap = StrokeCap.round;
  final Paint _shadowPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final isDark = activeColor.computeLuminance() < 0.5;

    double turns = currentAngle / (2 * pi);
    int level = turns.floor();
    if (level < 0) level = 0;

    double progressInLevel = turns - level;
    int activeTicks = (progressInLevel * tickCount).round();

    double pointerDialAngle = (currentAngle % (2 * pi));

    for (int i = 0; i < tickCount; i++) {
      double angle = (i * 2 * pi) / tickCount - pi / 2;
      double tickPos = (i * 2 * pi) / tickCount;

      double dist = (pointerDialAngle - tickPos).abs();
      if (dist > pi) dist = 2 * pi - dist;

      double sigma = 0.35;
      double bulgeFactor = exp(-(dist * dist) / (sigma * sigma));

      double tickMinHeight = radius * 0.05;
      double baseMaxGrowth = radius * 0.05;
      double dynamicGrowth = (level * 0.03 * radius);
      if (dynamicGrowth > radius * 0.15) dynamicGrowth = radius * 0.15;

      double currentHeight =
          tickMinHeight + ((baseMaxGrowth + dynamicGrowth) * bulgeFactor);

      bool isPassed = i <= activeTicks;

      _tickPaint.color = isPassed
          ? activeColor
          : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08));
      _tickPaint.strokeWidth = 2.5 + (1.5 * bulgeFactor);

      final innerRadius = radius - currentHeight;

      final startPoint = Offset(
        center.dx + innerRadius * cos(angle),
        center.dy + innerRadius * sin(angle),
      );
      final endPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      if (isPassed && bulgeFactor > 0.1) {
        _shadowPaint.color = activeColor.withValues(alpha: 0.6 * bulgeFactor);
        _shadowPaint.strokeWidth = 6.0 * bulgeFactor;
        canvas.drawLine(startPoint, endPoint, _shadowPaint);
      }

      canvas.drawLine(startPoint, endPoint, _tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DialTicksPainter oldDelegate) {
    return oldDelegate.currentAngle != currentAngle ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.tickCount != tickCount;
  }
}
