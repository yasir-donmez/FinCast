import 'package:flutter/material.dart';
import 'dart:ui';

class PrecisionCard extends StatelessWidget {
  final Widget child;
  final double scalingFactor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const PrecisionCard({
    super.key,
    required this.child,
    this.scalingFactor = 1.0,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16 * scalingFactor),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16 * scalingFactor),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: padding ?? EdgeInsets.all(10 * scalingFactor),
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
