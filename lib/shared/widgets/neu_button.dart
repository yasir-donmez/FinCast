import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';

/// Premium Neumorphism (Skeuomorphism) fiziksel buton.
/// Temaya (Aydınlık/Karanlık) duyarlıdır.
class NeuButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool isPrimary;

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
    Future.delayed(const Duration(milliseconds: 50), () {
      widget.onTap();
    });
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppColors.getSurface(context);
    final darkShadowColor = AppColors.getDarkShadow(context);
    final lightShadowColor = AppColors.getLightShadow(context);
    final innerSurfaceColor = AppColors.getInnerSurface(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: _isPressed ? null : surfaceColor,
          gradient: _isPressed
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    darkShadowColor.withValues(alpha: isDark ? 0.8 : 0.3),
                    innerSurfaceColor,
                    lightShadowColor.withValues(alpha: isDark ? 0.05 : 0.7),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                )
              : null,
          border: _isPressed
              ? Border.all(
                  color: darkShadowColor.withValues(alpha: isDark ? 0.8 : 0.3),
                  width: 1.5,
                )
              : null,
          boxShadow: _isPressed
              ? null
              : [
                  BoxShadow(
                    color: darkShadowColor.withValues(alpha: isDark ? 1.0 : 0.5),
                    offset: const Offset(6, 6),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: lightShadowColor.withValues(alpha: isDark ? 0.1 : 1.0),
                    offset: const Offset(-4, -4),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(AppSizes.paddingMedium),
            child: Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 150),
                scale: _isPressed ? 0.95 : 1.0,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
