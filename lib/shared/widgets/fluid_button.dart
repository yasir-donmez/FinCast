import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';
import 'fluid_container.dart';

/// FinCast Yeni Nesil "Sıvı & Organik" Buton (Fluid Button).
/// Basıldığında ölçeklenen (scale) ve derinlik değiştiren akışkan yapı.
class FluidButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double? width;
  final double? height;
  final Color? color;
  final bool isSecondary;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const FluidButton({
    super.key,
    required this.child,
    required this.onTap,
    this.width,
    this.height,
    this.color,
    this.isSecondary = false,
    this.borderRadius = AppSizes.radiusDefault,
    this.padding,
  });

  @override
  State<FluidButton> createState() => _FluidButtonState();
}

class _FluidButtonState extends State<FluidButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Buton rengi belirleme
    Color buttonColor;
    if (widget.isSecondary) {
      buttonColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.45); // Daha temiz beyaz cam bazı
    } else {
      buttonColor = widget.color ?? AppColors.getPrimary(context);
    }

    final textColor = widget.isSecondary 
        ? AppColors.getTextPrimary(context) 
        : (widget.color != null ? Colors.white : Colors.black87);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius * 1.5),
            boxShadow: [
              // Buton Glow (Işıltı) Etkisi
              if (!widget.isSecondary && !_isPressed)
                BoxShadow(
                  color: buttonColor.withValues(alpha: isDark ? 0.3 : 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
            ],
          ),
          child: FluidContainer(
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            borderRadius: widget.borderRadius * 1.5,
            color: buttonColor,
            isGlass: widget.isSecondary, // İkincil butonlar cam dokulu
            blur: 10,
            child: Center(
              child: DefaultTextStyle(
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
