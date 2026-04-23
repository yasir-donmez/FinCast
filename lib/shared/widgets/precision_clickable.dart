import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrecisionClickable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? color;
  final Color? pressedColor; // Basıldığındaki renk
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final bool showFlash;
  final double scaleOnPress;
  final bool useHaptic;

  const PrecisionClickable({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
    this.pressedColor,
    this.borderRadius,
    this.padding,
    this.width,
    this.height,
    this.showFlash = true,
    this.scaleOnPress = 0.95,
    this.useHaptic = true,
  });

  @override
  State<PrecisionClickable> createState() => _PrecisionClickableState();
}

class _PrecisionClickableState extends State<PrecisionClickable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Eğer pressedColor verilmişse onu kullan, yoksa parlama efekti için beyaz overlay kullan
    final backgroundColor = _isPressed && widget.pressedColor != null
        ? widget.pressedColor
        : widget.color ?? Colors.transparent;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        if (widget.useHaptic) HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleOnPress : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Eğer pressedColor yoksa ama flash isteniyorsa eski usul overlay
              if (widget.showFlash && _isPressed && widget.pressedColor == null)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                    ),
                  ),
                ),
              widget.child,
            ],
          ),
        ),
      ),
    );
  }
}
