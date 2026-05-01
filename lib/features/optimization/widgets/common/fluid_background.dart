import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_constants.dart';

class FluidBackground extends StatelessWidget {
  final Animation<double> animation;
  
  const FluidBackground({super.key, required this.animation});
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -100 + (math.sin(animation.value * 2 * math.pi) * 50),
              left: -50 + (math.cos(animation.value * 2 * math.pi) * 30),
              child: _Blob(
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.12 : 0.15,
                ),
                size: 300,
              ),
            ),
            Positioned(
              bottom: -50 + (math.cos(animation.value * 2 * math.pi) * 40),
              right: -80 + (math.sin(animation.value * 2 * math.pi) * 60),
              child: _Blob(
                color: AppColors.secondary.withValues(
                  alpha: isDark ? 0.1 : 0.12,
                ),
                size: 350,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  
  const _Blob({required this.color, required this.size});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.0)]),
      ),
    );
  }
}
