import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/neu_container.dart';

/// Hedef belirlemek için iPod tekerleği / Akıllı Termostat benzeri
/// fütüristik Neumorphic çevirmeli kadran (Dial)
class NeumorphicCircularSlider extends StatefulWidget {
  final double minValue;
  final double maxValue;
  final double initialValue;
  final ValueChanged<double> onChanged;

  const NeumorphicCircularSlider({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<NeumorphicCircularSlider> createState() =>
      _NeumorphicCircularSliderState();
}

class _NeumorphicCircularSliderState extends State<NeumorphicCircularSlider> {
  late double _currentValue;
  final double _dialSize = 250.0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Parmak hareketine göre değeri artır veya azalt
    // Sağa ve Yukarı kaydırmak değeri artırır
    double delta = details.delta.dx - details.delta.dy;

    setState(() {
      _currentValue += delta * 200; // Hassasiyet çarpanı
      _currentValue = _currentValue.clamp(widget.minValue, widget.maxValue);

      // Daha estetik durması için 500'er 500'er yuvarla
      double snappedValue = (_currentValue / 500).round() * 500.0;
      widget.onChanged(snappedValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Yüzdelik dolum oranını hesapla
    double fillPercentage =
        (_currentValue - widget.minValue) / (widget.maxValue - widget.minValue);
    // Dolum oranını bir çembere (açıya) çevir (0'dan 2 * pi'ye kadar, ancak estetik için biraz boşluk bırakıyoruz %80'lik bir kadran)
    double sweepAngle = fillPercentage * 2 * pi;

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      child: Center(
        child: SizedBox(
          width: _dialSize,
          height: _dialSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. En dış koruyucu çember (Neumorphic Çukur)
              NeuContainer(
                width: _dialSize,
                height: _dialSize,
                borderRadius: _dialSize / 2,
                isInnerShadow: true, // İçe göçen bir yuva
                padding: EdgeInsets.zero,
                child: const SizedBox.expand(),
              ),

              // 2. Parlayan Halka (Özel Çizim - CustomPaint)
              CustomPaint(
                size: Size(_dialSize, _dialSize),
                painter: _NeonRingPainter(
                  sweepAngle: sweepAngle,
                  neonColor: AppColors.primary,
                ),
              ),

              // 3. İçerdeki Dönen/Tıklanabilir gibi duran Merkez (Knob)
              NeuContainer(
                width: _dialSize - 50,
                height: _dialSize - 50,
                borderRadius: (_dialSize - 50) / 2,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "HEDEF BAKİYE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Değer Yazısı
                    Text(
                      "₺${(_currentValue / 500).round() * 500}",
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -1.0,
                        shadows: [
                          Shadow(color: AppColors.primary, blurRadius: 10),
                        ],
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "3 AY İÇİNDE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Neon ışıklı ilerleme çubuğunu kadrana çizen ressam sınıfı
class _NeonRingPainter extends CustomPainter {
  final double sweepAngle;
  final Color neonColor;

  _NeonRingPainter({required this.sweepAngle, required this.neonColor});

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = (size.width / 2) - 12; // İçeriye doğru biraz pay

    // Arka plan mat izi (Boş kısım)
    Paint trackPaint = Paint()
      ..color = AppColors.darkShadow.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Parlayan dolgu izi (Dolu kısım)
    Paint neonPaint = Paint()
      ..color = neonColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.solid,
        4,
      ); // Neon parlama efekti

    // Başlangıç açısı en üst nokta (-pi / 2)
    double startAngle = -pi / 2;

    // Önce arka mat izi çiz
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * pi, // Tam tur
      false,
      trackPaint,
    );

    // Sonra neon izi çiz (Değere göre)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      neonPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _NeonRingPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.neonColor != neonColor;
  }
}
