import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_constants.dart';

class FinancialReactorButton extends ConsumerStatefulWidget {
  final bool isAnalyzing;
  final VoidCallback onTap;
  final String label;

  const FinancialReactorButton({
    super.key,
    required this.isAnalyzing,
    required this.onTap,
    required this.label,
  });

  @override
  ConsumerState<FinancialReactorButton> createState() => _FinancialReactorButtonState();
}

class _FinancialReactorButtonState extends ConsumerState<FinancialReactorButton> with TickerProviderStateMixin {
  late final AnimationController _wobbleController, _pressController, _pulseController, _morphController;

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.isAnalyzing) _morphController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(FinancialReactorButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnalyzing != oldWidget.isAnalyzing) {
      if (widget.isAnalyzing) {
        _morphController.repeat(reverse: true);
      } else {
        _morphController.stop();
        _morphController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
        );
      }
    }
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _pressController.dispose();
    _pulseController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reactorColor = AppColors.getPrimary(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      onTap: widget.isAnalyzing
          ? null
          : () {
              HapticFeedback.heavyImpact();
              widget.onTap();
            },
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _wobbleController,
            _pressController,
            _pulseController,
            _morphController,
          ]),
          builder: (context, child) {
            final scale =
                (1.0 - (_pressController.value * 0.08)) *
                (1.0 + (_pulseController.value * 0.02));
            return Transform.rotate(
              angle: _morphController.value * math.pi * 0.5,
              child: Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Center(
                    child: _buildOrganicCore(
                      reactorColor,
                      _wobbleController.value,
                      _morphController.value,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrganicCore(Color color, double t, double m) {
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(64, 64),
            painter: _WaterDropPainterForButton(
              color: color,
              wobbleValue: t,
              morphValue: m,
            ),
          ),
          Icon(
            widget.isAnalyzing
                ? Icons.auto_awesome_rounded
                : Icons.psychology_rounded,
            color: Colors.white,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _WaterDropPainterForButton extends CustomPainter {
  final Color color;
  final double wobbleValue, morphValue;

  _WaterDropPainterForButton({
    required this.color,
    required this.wobbleValue,
    required this.morphValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final path = Path();
    for (int i = 0; i <= 60; i++) {
      double angle = (i * 2 * math.pi) / 60;
      double r =
          radius +
          (math.sin(angle * 3 + wobbleValue * 2 * math.pi) * 2.0) +
          (math.sin(angle * (2 + morphValue * 3)) * (morphValue * 6.0));
      double x = center.dx + r * math.cos(angle);
      double y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.4), color],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
