import 'dart:math' as math;
import 'package:flutter/material.dart';

/// FinCast "Akışkan Çift Yüzlü Kart" (Fluid 3D Flip Card).
/// Giriş ve Kayıt formlarını kartın ön ve arka yüzünde taşıyan, 
/// 3D döndürme animasyonuna sahip premium bileşen.
class PrecisionFlipCard extends StatefulWidget {
  final bool isFront;
  final Widget front;
  final Widget back;

  const PrecisionFlipCard({
    super.key,
    required this.isFront,
    required this.front,
    required this.back,
  });

  @override
  State<PrecisionFlipCard> createState() => _PrecisionFlipCardState();
}

class _PrecisionFlipCardState extends State<PrecisionFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutQuart,
    );

    if (!widget.isFront) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(PrecisionFlipCard oldWidget) {
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
    return RepaintBoundary(
      child: AnimatedBuilder(
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
      ),
    );
  }

  Widget _buildCardSide(Widget child) {
    return child;
  }
}
