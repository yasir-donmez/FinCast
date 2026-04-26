import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';
import 'precision_surface.dart';

class PrecisionGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final bool isGlass;
  final Color? color;
  final double blur;
  final Color? borderColor;
  final double? borderWidth;

  const PrecisionGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.isGlass = true,
    this.color,
    this.blur = 25.0,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return PrecisionSurface(
      padding: padding,
      borderRadius: borderRadius ?? AppSizes.radiusLarge,
      isGlass: isGlass,
      isConvex: false,
      blur: blur,
      color: color,
      borderColor: borderColor,
      borderWidth: borderWidth,
      child: child,
    );
  }
}
