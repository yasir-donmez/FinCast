import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_constants.dart';

/// FinCast Standart Organik Açılır Ekran (Fluid Sheet).
/// Tüm popup ve modal ekranlar bu bileşeni kullanarak standartlaşır.
class FluidSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final double? height;
  final bool showHandle;

  const FluidSheet({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.height,
    this.showHandle = true,
  });

  /// Statik bir yardımcı metod ile kolayca çağrılabilir
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    List<Widget>? actions,
    double? height,
    bool showHandle = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5), // Arka plan daha şeffaf
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 400),
      ),
      builder: (context) => FluidSheet(
        title: title,
        actions: actions,
        height: height,
        showHandle: showHandle,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final surfaceColor = AppColors.getSurface(context);
    
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Sayfa kapandığında tetiklenecek alan
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // Bombeli Sıvı Gövde
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              // Üstten aydınlanan bombeli gradyan
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
              color: surfaceColor.withValues(alpha: isDark ? 0.7 : 0.8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLarge * 2.5)),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.5),
                width: 1.0,
              ),
              boxShadow: [
                // Derin Alt Gölge
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLarge * 2.5)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showHandle) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.getTextSecondary(context).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              offset: const Offset(0, 1),
                              blurRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    if (title != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title!,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900, // Daha kalın, premium font
                                color: AppColors.getTextPrimary(context),
                                letterSpacing: -0.8,
                              ),
                            ),
                            if (actions != null) Row(children: actions!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    Flexible(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.95, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: ((value - 0.95) / 0.05).clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
                          child: child,
                        ),
                      ),
                    ),
                    
                    // Alt boşluk
                    SizedBox(height: MediaQuery.of(context).padding.bottom + AppSizes.paddingLarge),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
