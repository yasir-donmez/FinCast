import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_constants.dart';

class EtchedLiquidText extends StatefulWidget {
  final double progress;
  final Color activeColor;
  final String text;
  final double fontSize;

  const EtchedLiquidText({
    super.key,
    required this.progress,
    required this.activeColor,
    required this.text,
    this.fontSize = 44,
  });

  @override
  State<EtchedLiquidText> createState() => _EtchedLiquidTextState();
}

class _EtchedLiquidTextState extends State<EtchedLiquidText>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _levelController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Sıvı seviyesi için "nefes alma" animasyonu
    _levelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // İlk açılışta dolsun, sonra yavaşça inip çıksın
    _levelController.forward().then((_) {
      _levelController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _levelController]),
      builder: (context, child) {
        // progress 0 ise animasyonlu seviyeyi kullan (0.45 - 0.65 arası)
        final double effectiveLevel = widget.progress == 0 
            ? (0.45 + (_levelController.value * 0.2)) 
            : widget.progress;

        return CustomPaint(
          size: Size(widget.fontSize * 8, widget.fontSize * 2.2),
          painter: _EtchedLiquidPainter(
            progress: effectiveLevel,
            activeColor: widget.activeColor,
            text: widget.text,
            fontSize: widget.fontSize,
            waveValue: _waveController.value,
            context: context,
          ),
        );
      },
    );
  }
}

class _EtchedLiquidPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final String text;
  final double fontSize;
  final double waveValue;
  final BuildContext context;

  _EtchedLiquidPainter({
    required this.progress,
    required this.activeColor,
    required this.text,
    required this.fontSize,
    required this.waveValue,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.5,
      color: AppColors.getTextPrimary(context),
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final textRect = Rect.fromCenter(
      center: center,
      width: textPainter.width,
      height: textPainter.height,
    );

    canvas.saveLayer(textRect.inflate(50), Paint());

    // 1. RIM HIGHLIGHT
    final bezelTP = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(
          color: AppColors.getLightShadow(context).withValues(alpha: 0.4),
          shadows: [
            Shadow(
              color: AppColors.getLightShadow(context).withValues(alpha: 0.2),
              offset: const Offset(0.5, 0.7),
              blurRadius: 1,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    bezelTP.paint(canvas, textRect.topLeft + const Offset(0.5, 0.7));

    // 2. INNER WALL SHADOW
    final darkTP = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(color: Colors.black.withValues(alpha: 0.7)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    darkTP.paint(canvas, textRect.topLeft + const Offset(-0.8, -1.0));

    // 3. ETCHED BASE
    final baseTP = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(
          color: AppColors.getInnerSurface(context).withValues(alpha: 1.0),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0.2, 0.2),
              blurRadius: 1.5,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    baseTP.paint(canvas, textRect.topLeft);

    if (progress >= 0) {
      final double liquidLevel = textRect.bottom + 20 - (textRect.height * progress * 1.5);
      final Path wavePath = Path();
      wavePath.moveTo(textRect.left - 60, liquidLevel);
      for (double x = textRect.left - 60; x <= textRect.right + 60; x++) {
        final double wave1 = math.sin((x / 18) + (waveValue * 2 * math.pi)) * (fontSize * 0.15);
        final double wave2 = math.sin((x / 10) - (waveValue * 2 * math.pi)) * (fontSize * 0.05);
        wavePath.lineTo(x, liquidLevel + wave1 + wave2);
      }

      final Paint surfacePaint = Paint()
        ..color = activeColor.withValues(alpha: (0.9 * progress).clamp(0, 0.9))
        ..style = PaintingStyle.stroke
        ..strokeWidth = fontSize * 0.08
        ..blendMode = BlendMode.srcATop;
      canvas.drawPath(wavePath, surfacePaint);

      final Path submergedPath = Path.from(wavePath);
      submergedPath.lineTo(textRect.right + 60, textRect.bottom + 100);
      submergedPath.lineTo(textRect.left - 60, textRect.bottom + 100);
      submergedPath.close();

      final Paint eraserPaint = Paint()
        ..blendMode = BlendMode.clear
        ..color = Colors.black;
      canvas.drawPath(submergedPath, eraserPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EtchedLiquidPainter old) =>
      old.progress != progress ||
      old.waveValue != waveValue ||
      old.activeColor != activeColor;
}
