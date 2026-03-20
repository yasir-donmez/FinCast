import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/fluid_container.dart';

/// FinCast "Akışkan Çift Yüzlü Kart" (Fluid 3D Flip Card).
/// Giriş ve Kayıt formlarını kartın ön ve arka yüzünde taşıyan, 
/// 3D döndürme animasyonuna sahip premium bileşen.
class FluidFlipCard extends StatefulWidget {
  final bool isFront;
  final Widget front;
  final Widget back;

  const FluidFlipCard({
    super.key,
    required this.isFront,
    required this.front,
    required this.back,
  });

  @override
  State<FluidFlipCard> createState() => _FluidFlipCardState();
}

class _FluidFlipCardState extends State<FluidFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    );

    if (!widget.isFront) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(FluidFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFront != oldWidget.isFront) {
      if (widget.isFront) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Dönüş açısı (Radyan cinsinden, 0 ile Pi/180 arası)
        // Y ekseninde yatay 180 derece dönüş
        final double rotationValue = _animation.value * math.pi;
        final bool isBackVisible = rotationValue > math.pi / 2;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspektif (Derinlik hissi)
            ..rotateY(rotationValue),
          child: isBackVisible
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi), // Arka tarafı düzelt
                  child: _buildCardSide(widget.back),
                )
              : _buildCardSide(widget.front),
        );
      },
    );
  }

  Widget _buildCardSide(Widget child) {
    return FluidContainer(
      width: double.infinity,
      borderRadius: AppSizes.radiusLarge,
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      isGlass: true,
      blur: 35,
      margin: EdgeInsets.zero,
      child: child,
    );
  }
}
