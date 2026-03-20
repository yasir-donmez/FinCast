import 'dart:math' as math;
import 'package:flutter/material.dart';

/// FinCast "Sıvı Geçiş Dalgası" (Liquid Transition Wave).
/// Ekranın bir köşesinden başlayıp tüm ekranı kaplayan enerjik bir renk dalgası.
class LiquidWave extends StatefulWidget {
  final AnimationController controller;
  final Color color;
  final bool isTriggered;

  const LiquidWave({
    super.key,
    required this.controller,
    required this.color,
    required this.isTriggered,
  });

  @override
  State<LiquidWave> createState() => _LiquidWaveState();
}

class _LiquidWaveState extends State<LiquidWave> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _WavePainter(
            progress: widget.controller.value,
            color: widget.color,
            isTriggered: widget.isTriggered,
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isTriggered;

  _WavePainter({
    required this.progress,
    required this.color,
    required this.isTriggered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.6 * (1 - progress))
      ..style = PaintingStyle.fill;

    // Dalga Merkez Başlangıcı (Sol Üst)
    const Offset center = Offset(0, 0);
    // Maksimum çap (Ekran köşegeni)
    final double maxRadius = math.sqrt(size.width * size.width + size.height * size.height);
    
    // Geçiş İlerlemesi (Surge Effect)
    final double currentRadius = maxRadius * progress * 1.5;

    final path = Path();
    
    // Organik dalga formu (Dalgalı çember dilimi)
    for (double i = 0; i <= 90; i += 2) {
      final double radians = i * (math.pi / 180);
      // Dalga etkisi eklemek için sinüs vari bozulma
      final double waveDistortion = 30 * math.sin(progress * 5 * math.pi + radians * 8);
      
      final double x = center.dx + (currentRadius + waveDistortion) * math.cos(radians);
      final double y = center.dy + (currentRadius + waveDistortion) * math.sin(radians);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.lineTo(0, size.height); // Alt Köşe
    path.lineTo(0, 0); // Başlangıç
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}
