import 'package:flutter/material.dart';
import '../../../../core/theme/app_constants.dart';

class ThinkingOrb extends StatelessWidget {
  final Animation<double> breathe;
  
  const ThinkingOrb({super.key, required this.breathe});
  
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: breathe,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.psychology_rounded, color: Colors.white, size: 40),
        ),
      ),
    );
  }
}
