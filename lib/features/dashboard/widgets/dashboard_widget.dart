import 'package:flutter/material.dart';
import '../../../shared/widgets/precision_glass_card.dart';
import '../../../core/theme/app_constants.dart';

/// Dashboard widget'larının boyut tipleri
enum DashboardWidgetSize {
  small,  // 1x1
  wide,   // 2x1
  large,  // 2x2
}

/// Tüm Dashboard widget'ları için temel sarmalayıcı.
/// Cam efekti, köşeler ve standart padding'i yönetir.
class DashboardWidget extends StatefulWidget {
  final Widget child;
  final DashboardWidgetSize size;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isEditing;

  const DashboardWidget({
    super.key,
    required this.child,
    this.size = DashboardWidgetSize.large,
    this.onTap,
    this.onLongPress,
    this.isEditing = false,
  });

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _wiggleController;
  late Animation<double> _wiggleAnimation;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    
    _wiggleAnimation = Tween<double>(begin: -0.015, end: 0.015).animate(
      CurvedAnimation(parent: _wiggleController, curve: Curves.easeInOut),
    );

    if (widget.isEditing) {
      _wiggleController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(DashboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing && !oldWidget.isEditing) {
      _wiggleController.repeat(reverse: true);
    } else if (!widget.isEditing && oldWidget.isEditing) {
      _wiggleController.stop();
      _wiggleController.reset();
    }
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _wiggleAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: widget.isEditing ? _wiggleAnimation.value : 0,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.isEditing ? null : widget.onTap,
        onLongPress: widget.onLongPress,
        child: PrecisionGlassCard(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Stack(
            children: [
              widget.child,
              if (widget.isEditing)
                Positioned(
                  top: -8,
                  left: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.remove, size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
