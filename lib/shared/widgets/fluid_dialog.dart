import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';
import 'fluid_container.dart';

class FluidDialog extends StatelessWidget {
  final Widget? icon;
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final Color? accentColor;

  const FluidDialog({
    super.key,
    this.icon,
    this.title,
    this.content,
    this.actions,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = accentColor ?? AppColors.getPrimary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Arka Plan Parlama Efekti (Deep Glow)
          Positioned(
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    activeColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    activeColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 2. Ana Konteyner
          FluidContainer(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
            borderRadius: 32,
            isGlass: true,
            blur: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // İkon Alanı
                if (icon != null) ...[
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: activeColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: activeColor.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: IconTheme(
                            data: IconThemeData(color: activeColor, size: 32),
                            child: icon!,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Başlık
                if (title != null) ...[
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.getTextPrimary(context),
                      letterSpacing: -0.5,
                      fontSize: 22,
                    ) ?? const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                    textAlign: TextAlign.center,
                    child: title!,
                  ),
                  const SizedBox(height: 12),
                ],

                // İçerik
                if (content != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.getTextSecondary(context),
                        height: 1.5,
                        fontSize: 15,
                      ) ?? const TextStyle(fontSize: 15, height: 1.5),
                      textAlign: TextAlign.center,
                      child: content!,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Butonlar
                if (actions != null) ...[
                  Row(
                    children: actions!.map((action) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: action == actions!.first ? 0 : 8),
                          child: action,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          
          // 3. Üst Süsleme (Opsiyonel - Tasarımı zenginleştirmek için)
          if (icon == null)
            Positioned(
              top: 0,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<T?> showFluidDialog<T>({
  required BuildContext context,
  Widget? icon,
  Widget? title,
  Widget? content,
  List<Widget>? actions,
  Color? accentColor,
}) {
  return showGeneralDialog<T>(
    context: context,
    pageBuilder: (context, animation, secondaryAnimation) {
      return FluidDialog(
        icon: icon,
        title: title,
        content: content,
        actions: actions,
        accentColor: accentColor,
      );
    },
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 400),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnimation),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

class FluidDialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const FluidDialogButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FluidContainer(
        padding: const EdgeInsets.symmetric(vertical: 12),
        borderRadius: 16,
        color: color.withValues(alpha: 0.15),
        borderWidth: 1.5,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
