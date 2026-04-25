import 'package:flutter/material.dart';
import 'precision_clickable.dart';

/// FinCast Standart Tasarımlı İkon Butonu.
/// PrecisionClickable kullanarak premium tıklama hissiyatı ve standart görsel yapı sunar.
class PrecisionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double padding;
  final double borderRadius;

  const PrecisionIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.backgroundColor,
    this.size = 22,
    this.padding = 10,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).primaryColor;
    final bg = backgroundColor ?? themeColor.withValues(alpha: 0.1);

    return PrecisionClickable(
      onTap: onTap,
      color: bg,
      pressedColor: themeColor.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(borderRadius),
      padding: EdgeInsets.all(padding),
      scaleOnPress: 0.92,
      child: Icon(
        icon,
        color: themeColor,
        size: size,
      ),
    );
  }
}
