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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: isDark 
          ? Colors.black.withValues(alpha: 0.5) 
          : Colors.black.withValues(alpha: 0.1), // Daha da şeffaf karartma
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
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9, // Ekranın %90'ından fazlasını kaplamasın
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              // Üstten aydınlanan bombeli gradyan
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
              color: surfaceColor.withValues(alpha: isDark ? 0.94 : 1.0), // Opaklığı artırdık (0.85 -> 0.94)
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLarge * 2.5)),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLarge * 2.5)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0), // Blur azaltıldı (30 -> 20)
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
                            Expanded(
                              child: Text(
                                title!,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.getTextPrimary(context),
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ),
                            if (actions != null) Row(children: actions!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
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
                            padding: const EdgeInsets.only(
                              left: AppSizes.paddingLarge,
                              right: AppSizes.paddingLarge,
                              bottom: AppSizes.paddingLarge,
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                    
                    // Alt boşluk (Güvenli alan kontrolü ile)
                    SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : AppSizes.paddingLarge),
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
