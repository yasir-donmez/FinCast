import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';

/// Premium Neumorphism (Skeuomorphism) kart / yüzey bileşeni.
/// Temaya (Aydınlık/Karanlık) duyarlıdır.
class NeuContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isInnerShadow; // İçe gömük (Debossed) hissiyatı için

  const NeuContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = AppSizes.radiusDefault,
    this.isInnerShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = AppColors.getSurface(context);
    final darkShadowColor = AppColors.getDarkShadow(context);
    final lightShadowColor = AppColors.getLightShadow(context);
    final innerSurfaceColor = AppColors.getInnerSurface(context);

    if (isInnerShadow) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: darkShadowColor.withValues(alpha: isDark ? 0.8 : 0.3),
            width: 1.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              darkShadowColor.withValues(alpha: isDark ? 0.6 : 0.2),
              innerSurfaceColor,
              lightShadowColor.withValues(alpha: isDark ? 0.05 : 0.7),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSizes.paddingMedium),
            child: child,
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: darkShadowColor.withValues(alpha: isDark ? 0.7 : 0.3),
            offset: Offset(isDark ? 6 : 4, isDark ? 6 : 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: lightShadowColor.withValues(alpha: isDark ? 0.05 : 0.9),
            offset: Offset(isDark ? -6 : -4, isDark ? -6 : -4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
