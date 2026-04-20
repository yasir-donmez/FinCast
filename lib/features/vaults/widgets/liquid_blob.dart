import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class LiquidBlob extends StatefulWidget {
  final Color color;
  final double size;
  const LiquidBlob({super.key, required this.color, required this.size});

  @override
  State<LiquidBlob> createState() => _LiquidBlobState();
}

class _LiquidBlobState extends State<LiquidBlob> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = _controller.value * 2 * math.pi;
        final double dx = math.sin(t) * 20;
        final double dy = math.cos(t) * 20;
        
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [widget.color, widget.color.withValues(alpha: 0)],
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.transparent),
            ),
          ),
        );
      },
    );
  }
}
