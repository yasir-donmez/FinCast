import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';
import 'fluid_container.dart';

class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final bool isGlass;
  final Color? color;
  final double blur;

  const PremiumGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.isGlass = true,
    this.color,
    this.blur = 25.0,
  });

  @override
  Widget build(BuildContext context) {
    return FluidContainer(
      padding: padding,
      borderRadius: borderRadius ?? AppSizes.radiusLarge,
      isGlass: isGlass,
      isConvex: false,
      blur: blur,
      color: color,
      child: child,
    );
  }
}
