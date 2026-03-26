import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../core/theme/app_constants.dart';

/// Ultra-Profesyonel Neumorphism (Skeuomorphism) bileşeni.
/// Işık kırılmaları, bezel efektleri ve derinlik katmanları içerir.
class NeuContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isInnerShadow; 
  final Color? color;
  final bool showBezel; // Kenar parlaması efekti

  const NeuContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = AppSizes.radiusDefault,
    this.isInnerShadow = false,
    this.color,
    this.showBezel = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ?? AppColors.getBackground(context);
    final surfaceColor = color ?? AppColors.getSurface(context);
    
    // Profesyonel renk paleti (Zemin renginden türetilen akıllı gölgeler)
    final darkShadow = isDark ? Colors.black.withValues(alpha: 0.8) : Colors.grey.withValues(alpha: 0.4);
    final lightShadow = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;

    if (isInnerShadow) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          // Kenar parlaması (Bezel): Çukurun dış kenarının ışığı yakalaması
          border: showBezel ? Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
            width: 0.5,
          ) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            children: [
              // Ana Zemin
              Container(color: bgColor),
              
              // ÜST-SOL Karanlık Gölge (Derinlik)
              Positioned.fill(
                child: _InnerShadowEffect(
                  borderRadius: borderRadius,
                  shadowColor: darkShadow,
                  offset: const Offset(6, 6),
                  blur: 12,
                ),
              ),
              
              // ALT-SAĞ Aydınlık Gölge (Yansıma)
              Positioned.fill(
                child: _InnerShadowEffect(
                  borderRadius: borderRadius,
                  shadowColor: lightShadow,
                  offset: const Offset(-4, -4),
                  blur: 8,
                ),
              ),
              
              // İçerik
              Padding(
                padding: padding ?? const EdgeInsets.all(AppSizes.paddingMedium),
                child: child,
              ),
            ],
          ),
        ),
      );
    }

    // DIŞA ÇIKIK (CONVEX) TASARIM
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Ana gölge (Derinlik)
          BoxShadow(
            color: darkShadow,
            offset: Offset(isDark ? 8 : 6, isDark ? 8 : 6),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          // Işık (Hacim)
          BoxShadow(
            color: lightShadow,
            offset: Offset(isDark ? -6 : -4, isDark ? -6 : -4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
        // Kavisli Yüzey Gradyanı (Specular Highlight simülasyonu)
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [
                surfaceColor.withValues(alpha: 1.0), 
                surfaceColor.withValues(alpha: 0.8),
                Colors.black.withValues(alpha: 0.4)
              ]
            : [
                Colors.white, 
                surfaceColor.withValues(alpha: 0.95),
                surfaceColor.withValues(alpha: 0.85)
              ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: child,
    );
  }
}

class _InnerShadowEffect extends StatelessWidget {
  final double borderRadius;
  final Color shadowColor;
  final Offset offset;
  final double blur;

  const _InnerShadowEffect({
    required this.borderRadius,
    required this.shadowColor,
    required this.offset,
    required this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _InnerShadowPainter(
        borderRadius: borderRadius,
        shadowColor: shadowColor,
        offset: offset,
        blur: blur,
      ),
    );
  }
}

class _InnerShadowPainter extends CustomPainter {
  final double borderRadius;
  final Color shadowColor;
  final Offset offset;
  final double blur;

  _InnerShadowPainter({
    required this.borderRadius,
    required this.shadowColor,
    required this.offset,
    required this.blur,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    final shadowRect = RRect.fromRectAndRadius(
      rect.shift(offset),
      Radius.circular(borderRadius),
    );

    canvas.save();
    canvas.clipRRect(rrect);
    
    final shadowPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(rrect)
      ..addRRect(shadowRect);

    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InnerShadowPainter oldDelegate) => true;
}
