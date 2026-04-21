import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_constants.dart';
import '../../l10n/app_localizations.dart';

class ThemeRevealButton extends ConsumerStatefulWidget {
  final Color activeColor;
  const ThemeRevealButton({super.key, required this.activeColor});

  @override
  ConsumerState<ThemeRevealButton> createState() => _ThemeRevealButtonState();
}

class _ThemeRevealButtonState extends ConsumerState<ThemeRevealButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  OverlayEntry? _overlayEntry;
  ui.Image? _screenshot;
  final GlobalKey _toggleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
    final boundary = rootRepaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    
    final pixelRatio = View.of(context).devicePixelRatio;
    _screenshot = await boundary.toImage(pixelRatio: pixelRatio);
  }

  void _handleToggle() async {
    if (_controller.isAnimating) return;
    if (!mounted) return;

    // 1. Capture snapshot of OLD theme
    await _captureSnapshot(context);
    if (_screenshot == null) return;

    final settings = ref.read(settingsProvider);
    final currentThemeIndex = settings.themeModeIndex;
    final brightness = MediaQuery.of(context).platformBrightness;
    final bool isActuallyDark = currentThemeIndex == 2 || (currentThemeIndex == 0 && brightness == Brightness.dark);
    final int nextThemeIndex = isActuallyDark ? 1 : 2;

    // 2. Capture EXACT toggle position for the reveal start
    final RenderBox? renderBox = _toggleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final center = renderBox.localToGlobal(renderBox.size.center(Offset.zero));

    // 3. Change theme underneath
    await ref.read(settingsProvider.notifier).setThemeMode(nextThemeIndex);

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

    // 5. Expand the hole from the toggle center
    await _controller.forward(from: 0.0);
    
    _removeOverlay();
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = settings.themeModeIndex == 2 || (settings.themeModeIndex == 0 && brightness == Brightness.dark);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.activeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: widget.activeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                l10n.themeMode,
                style: TextStyle(
                  color: AppColors.getTextPrimary(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          
          // THE ROUND TOGGLE
          GestureDetector(
            onTap: _handleToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 72,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.getInnerSurface(context),
                border: Border.all(
                  color: widget.activeColor.withValues(alpha: 0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    left: isDark ? 36 : 4,
                    top: 4,
                    child: Container(
                      key: _toggleKey, // Point of origin for animation
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.activeColor,
                        boxShadow: [
                          BoxShadow(
                            color: widget.activeColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                            key: ValueKey(isDark),
                            color: Colors.black,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

    // 1. Draw old theme
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.fill,
    );

    // 2. Cut a hole exactly at 'center'
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
