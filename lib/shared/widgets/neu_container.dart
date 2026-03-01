import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';

/// Premium Dark Neumorphism (Skeuomorphism) kart / yüzey bileşeni.
/// Dışa Kabartma (Embossed) ve İçe Çökük (Debossed) efektleri sağlar.
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
    this.isInnerShadow = false, // Varsayılan: Dışa kabartık (Embossed)
  });

  @override
  Widget build(BuildContext context) {
    if (isInnerShadow) {
      // Çukur / Kuyu Görünümü (Gerçek Debossed simülasyonu)
      return Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppColors.darkShadow.withValues(
              alpha: 0.8,
            ), // Çukurun üst-sol karanlık sınırı
            width: 1.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkShadow.withValues(
                alpha: 0.6,
              ), // Yukarıdan düşen iç gölge
              AppColors.innerSurface,
              AppColors.lightShadow.withValues(
                alpha: 0.05,
              ), // Aşağıdan vuran cılız ışık
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

    // Fiziksel Yüzey / Dışa Kabartma (Embossed)
    // Fiziksel Kartlar, Çevirmeli Kadranın Zemini vb.
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface, // Mat antresit gri
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          // Sağ Alt - Derin Karanlık Gölge
          BoxShadow(
            color: AppColors.darkShadow,
            offset: Offset(8, 8),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          // Sol Üst - Yumuşak Işık Yansıması
          BoxShadow(
            color: AppColors.lightShadow,
            offset: Offset(-6, -6),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
