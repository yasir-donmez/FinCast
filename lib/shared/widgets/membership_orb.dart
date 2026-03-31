import 'package:flutter/material.dart';
import 'dart:math' as math;

/// FinCast Premium Üyelik Küresi (Premium Orb)
/// Animasyonlu, akışkan ve gerçekçi cam görünümlü bir küre sunar.
class MembershipOrb extends StatefulWidget {
  final Color color;
  final double size;
  final double morphFactor;
  final double wobbleValue; // External override if needed

  const MembershipOrb({
    super.key,
    required this.color,
    this.size = 50,
    this.morphFactor = 1.0,
    this.wobbleValue = -1, // -1 means use internal animator
  });

  @override
  State<MembershipOrb> createState() => _MembershipOrbState();
}

class _MembershipOrbState extends State<MembershipOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentWobble = widget.wobbleValue >= 0 ? widget.wobbleValue : _controller.value;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _WaterDropPainter(
            color: widget.color,
            morphFactor: widget.morphFactor,
            wobbleValue: currentWobble,
          ),
        );
      },
    );
  }
}

class _WaterDropPainter extends CustomPainter {
  final Color color;
  final double morphFactor;
  final double wobbleValue;

  _WaterDropPainter({
    required this.color, 
    required this.morphFactor,
    required this.wobbleValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final t = wobbleValue * 2 * math.pi;
    
    // 1. DIŞ GÖLGE (Daha yumuşak ve geniş)
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.12 * morphFactor)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center.translate(8 * morphFactor, 10 * morphFactor), radius * morphFactor * 0.75, shadowPaint);

    // 2. CAM KABUK (Thick Glass Shell - Fresnel Effect)
    final shellPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.1 * morphFactor), // Merkez: Şeffaf Cam
          color.withValues(alpha: 0.4 * morphFactor), // Orta: Renk geçişi
          color.withValues(alpha: 0.8 * morphFactor), // Kenar: Kalın cam etkisi
        ],
        stops: const [0.0, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * morphFactor));
    canvas.drawCircle(center, radius * morphFactor, shellPaint);

    // 3. İÇ SIVI DERİNLİĞİ (Inner Liquid Volume)
    final liquidPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.3 * morphFactor),
          Colors.transparent,
        ],
        center: const Alignment(0.0, 0.2), // Altta biriken sıvı hissi
        radius: 0.8,
      ).createShader(Rect.fromCircle(center: center, radius: radius * morphFactor));
    canvas.drawCircle(center, radius * morphFactor * 0.9, liquidPaint);

    // 4. İÇTEKİ NESNELER (Liquid Particles - 3D Layers)
    if (morphFactor > 0.3) {
      _drawLiquidParticle(canvas, center, radius, morphFactor, t * 1.0, 0, 0.4, 3.5, 0.3); // 1.0 Tam tur
      _drawLiquidParticle(canvas, center, radius, morphFactor, t * 2.0, 2.5, 0.6, 5.5, 0.6); // 2.0 Tam tur
      _drawLiquidParticle(canvas, center, radius, morphFactor, t * 1.0, 4.5, 1.0, 8.0, 0.9); // 1.0 Tam tur
    }
 
    // 5. CAM YANSIMALARI (Refractive Highlights) - KALDIRILDI (USER İsteği)
    /*
    final mainHighlightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.4 * morphFactor),
          Colors.white.withValues(alpha: 0.0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius * morphFactor));
    
    canvas.drawOval(
      Rect.fromLTWH(
        center.dx - radius * 0.6 * morphFactor,
        center.dy - radius * 0.7 * morphFactor,
        radius * 0.8 * morphFactor,
        radius * 0.5 * morphFactor,
      ),
      mainHighlightPaint,
    );

    final glancePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6 * morphFactor)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-radius * 0.45 * morphFactor, -radius * 0.45 * morphFactor),
        width: radius * 0.25 * morphFactor,
        height: radius * 0.15 * morphFactor,
      ),
      glancePaint,
    );
    */
 
    // 6. KENAR IŞIĞI (Rim Light - Glass Edge)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * morphFactor
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.5 * morphFactor),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.5],
        transform: const GradientRotation(-math.pi / 3),
      ).createShader(Rect.fromCircle(center: center, radius: radius * morphFactor));
    canvas.drawCircle(center, radius * morphFactor * 0.97, rimPaint);
  }

  void _drawLiquidParticle(
    Canvas canvas, 
    Offset center, 
    double radius, 
    double morph, 
    double t, 
    double offset, 
    double scale,
    double size,
    double opacity
  ) {
    final dx = math.cos(t + offset) * (radius * 0.5 * scale) * morph;
    final dy = math.sin(t + offset) * (radius * 0.4 * scale) * morph;
    final pos = center + Offset(dx, dy);
    
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * morph)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, (1 - opacity) * 4 + 1);
    
    final s = size * (1.0 + 0.05 * math.sin(t * 2)) * morph;
    
    final path = Path();
    path.moveTo(pos.dx, pos.dy - s);
    path.quadraticBezierTo(pos.dx + s * 0.2, pos.dy - s * 0.2, pos.dx + s, pos.dy);
    path.quadraticBezierTo(pos.dx + s * 0.2, pos.dy + s * 0.2, pos.dx, pos.dy + s);
    path.quadraticBezierTo(pos.dx - s * 0.2, pos.dy + s * 0.2, pos.dx - s, pos.dy);
    path.quadraticBezierTo(pos.dx - s * 0.2, pos.dy - s * 0.2, pos.dx, pos.dy - s);
    
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(t * 0.5); // 0.5 çarpanı (180 derece) 4-yüzlü simetride kusursuz döngü sağlar
    canvas.translate(-pos.dx, -pos.dy);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WaterDropPainter oldDelegate) => 
    oldDelegate.morphFactor != morphFactor || oldDelegate.wobbleValue != wobbleValue;
}
