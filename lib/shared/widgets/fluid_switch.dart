import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_constants.dart';

class FluidSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final IconData? activeIcon;
  final IconData? inactiveIcon;
  final double scalingFactor;

  const FluidSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.activeIcon = Icons.check_rounded,
    this.inactiveIcon = Icons.close_rounded,
    this.scalingFactor = 1.0,
  });

  @override
  State<FluidSwitch> createState() => _FluidSwitchState();
}

class _FluidSwitchState extends State<FluidSwitch> {
  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppColors.getPrimary(context);
    final s = widget.scalingFactor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onChanged(!widget.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 72 * s,
        height: 40 * s,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20 * s),
          color: AppColors.getInnerSurface(context),
          border: Border.all(
            color: widget.value ? activeColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
          gradient: widget.value
              ? LinearGradient(
                  colors: [
                    activeColor.withValues(alpha: 0.2),
                    activeColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: Offset(0, 2 * s),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Thumb
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              left: widget.value ? 38 * s : 4 * s,
              top: 5 * s, // (40 - 30) / 2 = 5
              child: Container(
                width: 30 * s,
                height: 30 * s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.value ? activeColor : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.value ? activeColor : Colors.black).withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Icon(
                      (widget.value ? widget.activeIcon : widget.inactiveIcon) ??
                          (widget.value ? Icons.check_rounded : Icons.close_rounded),
                      key: ValueKey(widget.value),
                      color: widget.value ? Colors.black : Colors.grey[700],
                      size: 16 * s,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
