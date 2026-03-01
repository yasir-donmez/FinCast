import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';

/// Premium Dark Neumorphism (Skeuomorphism) fiziksel buton.
/// Basıldığında gerçekçi bir şekilde içeri doğru göçer (Debossed).
class NeuButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool isPrimary; // True ise parıldayan bir ışık veya ikon barındırabilir

  const NeuButton({
    super.key,
    required this.child,
    required this.onTap,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = AppSizes.radiusDefault,
    this.isPrimary = false,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    // Tıklandıktan çok kısa süre sonra tetiklensin ki basma hissi tam geçsin
    Future.delayed(const Duration(milliseconds: 50), () {
      widget.onTap();
    });
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150), // Fiziksel yaylanma hızı
        curve: Curves.easeOutCubic,
        width: widget.width,
        height: widget.height,
        // Basılı değilse Dışa Kabartık (isInnerShadow: false)
        // Basılıysa İçe Çökük (isInnerShadow: true)
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: _isPressed ? null : AppColors.surface,
          gradient: _isPressed
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.darkShadow.withValues(
                      alpha: 0.8,
                    ), // Derin iç gölge
                    AppColors.innerSurface,
                    AppColors.lightShadow.withValues(
                      alpha: 0.05,
                    ), // Hafif ışık sekmesi
                  ],
                  stops: const [0.0, 0.4, 1.0],
                )
              : null,
          border: _isPressed
              ? Border.all(
                  color: AppColors.darkShadow.withValues(alpha: 0.8),
                  width: 1.5,
                )
              : null,
          boxShadow: _isPressed
              ? null
              : const [
                  // Fiziksel buton kabartma gölgeleri (Embossed)
                  BoxShadow(
                    color: AppColors.darkShadow,
                    offset: Offset(6, 6),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: AppColors.lightShadow,
                    offset: Offset(-4, -4),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Padding(
            padding:
                widget.padding ?? const EdgeInsets.all(AppSizes.paddingMedium),
            child: Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 150),
                scale: _isPressed
                    ? 0.95
                    : 1.0, // İçindeki ikon/metin basılınca azıcık küçülsün
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
