import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_constants.dart';
import '../../l10n/app_localizations.dart';
import 'fluid_switch.dart';

// Global key for screenshot boundary
// Global key is imported from settings_provider

class ThemeRevealButton extends ConsumerStatefulWidget {
  final Color activeColor;
  const ThemeRevealButton({super.key, required this.activeColor});

  @override
  ConsumerState<ThemeRevealButton> createState() => _ThemeRevealButtonState();
}

class _ThemeRevealButtonState extends ConsumerState<ThemeRevealButton> with TickerProviderStateMixin {
  late AnimationController _controller;
  OverlayEntry? _overlayEntry;
  ui.Image? _screenshot;
  final GlobalKey _switchKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _screenshot?.dispose();
    _screenshot = null;
  }

  Future<void> _captureSnapshot(BuildContext context) async {
    try {
      final boundary = rootRepaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final pixelRatio = View.of(context).devicePixelRatio;
      _screenshot = await boundary.toImage(pixelRatio: pixelRatio);
    } catch (e) {
      debugPrint('ThemeReveal screenshot error: $e');
      _screenshot = null;
    }
  }

  void _handleToggle(bool val) async {
    if (_controller.isAnimating) return;
    if (!mounted) return;

    // 1. Capture snapshot of OLD theme
    await _captureSnapshot(context);
    if (_screenshot == null || !mounted) return;

    // 2. Capture switch position for reveal start
    final RenderBox? renderBox = _switchKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final center = renderBox.localToGlobal(renderBox.size.center(Offset.zero));

    // 3. Change theme underneath
    await ref.read(settingsProvider.notifier).setThemeMode(val ? 2 : 1);

    // 4. Show OLD snapshot in overlay
    if (!mounted) return;
    _overlayEntry = OverlayEntry(
      builder: (context) => _RevealOverlay(
        center: center,
        animation: _controller,
        image: _screenshot!,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // 5. Reveal the new theme
    await _controller.forward(from: 0.0);
    
    _removeOverlay();
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.activeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.activeColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: widget.activeColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              l10n.themeMode,
              style: TextStyle(
                color: AppColors.getTextPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FluidSwitch(
            key: _switchKey,
            value: isDark,
            activeColor: widget.activeColor,
            onChanged: _handleToggle,
            activeIcon: Icons.dark_mode_rounded,
            inactiveIcon: Icons.light_mode_rounded,
          ),
        ],
      ),
    );
  }
}

class _RevealOverlay extends StatelessWidget {
  final Offset center;
  final Animation<double> animation;
  final ui.Image image;

  const _RevealOverlay({
    required this.center,
    required this.animation,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _InverseCircularRevealPainter(
            center: center,
            fraction: animation.value,
            image: image,
          ),
        );
      },
    );
  }
}

class _InverseCircularRevealPainter extends CustomPainter {
  final Offset center;
  final double fraction;
  final ui.Image image;

  _InverseCircularRevealPainter({
    required this.center,
    required this.fraction,
    required this.image,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxRadius = _calcMaxRadius(center, size);
    final radius = maxRadius * fraction;

    canvas.saveLayer(Offset.zero & size, Paint());

    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.fill,
    );

    final erasePaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, erasePaint);

    canvas.restore();
  }

  double _calcMaxRadius(Offset center, Size size) {
    final w = math.max(center.dx, size.width - center.dx);
    final h = math.max(center.dy, size.height - center.dy);
    return math.sqrt(w * w + h * h);
  }

  @override
  bool shouldRepaint(covariant _InverseCircularRevealPainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}
