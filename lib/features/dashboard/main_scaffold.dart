import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_constants.dart';
import '../transactions/add_transaction_sheet.dart';
import '../vaults/vaults_providers.dart';
import 'dashboard_screen.dart';
import 'dashboard_providers.dart';
import '../vaults/vaults_screen.dart';
import '../optimization/optimization_screen.dart';
import '../profile/profile_screen.dart';
import '../../shared/widgets/fluid_container.dart';
import '../../shared/widgets/fluid_sheet.dart';
import 'package:flutter/rendering.dart';
import '../../core/services/subscription_service.dart';
import '../subscription/widgets/pro_upgrade_sheet.dart';

import 'dashboard_scroll_provider.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isProButtonVisible = true;
  AnimationController? _wobbleController;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const VaultsScreen(),
    const OptimizationScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardScrollProvider).addListener(_onScroll);
    });
  }

  @override
  void dispose() {
    _wobbleController?.dispose();
    super.dispose();
  }

  void _onScroll() {
    final controller = ref.read(dashboardScrollProvider);
    if (!controller.hasClients) return;

    // Sayfanın en tepesindeyse her zaman göster
    if (controller.offset < 50) {
      if (!_isProButtonVisible) setState(() => _isProButtonVisible = true);
      return;
    }

    if (controller.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isProButtonVisible) setState(() => _isProButtonVisible = false);
    } else if (controller.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isProButtonVisible) setState(() => _isProButtonVisible = true);
    }
  }

  void _openTransactionSheet() {
    int? preselectedVaultId;
    if (_currentIndex == 1) {
      final selectedId = ref.read(selectedVaultProvider);
      if (selectedId != null && selectedId.startsWith('v_')) {
        preselectedVaultId = int.tryParse(selectedId.replaceFirst('v_', ''));
      }
    }

    FluidSheet.show(
      context: context,
      title: AppLocalizations.of(context)!.addTransaction,
      child: AddTransactionSheet(initialVaultId: preselectedVaultId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = AppColors.getBackground(context);
    final subscription = ref.watch(subscriptionServiceProvider);
    final activeColor = ref.watch(rotaryColorProvider);

    
    // Klavye/Odak kontrolü
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    // Sadece Dashboard sayfasında ve scroll/klavye durumuna göre göster
    final shouldShowButton = _currentIndex == 0 && _isProButtonVisible && !isKeyboardVisible;


    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          backgroundColor: backgroundColor,
          body: _pages[_currentIndex],
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: FluidContainer(
                height: 76,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                borderRadius: 38,
                isGlass: true,
                blur: Theme.of(context).brightness == Brightness.dark ? 20 : 15,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, AppLocalizations.of(context)!.home),
                    _buildNavItem(1, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, AppLocalizations.of(context)!.vaults),
                    
                    _buildCenterFab(),
                    
                    _buildNavItem(2, Icons.bar_chart_rounded, Icons.bar_chart_outlined, AppLocalizations.of(context)!.analysis),
                    _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded, AppLocalizations.of(context)!.profile),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 💎 PRO İKONU: Navbardan yükselen gerçekçi sıvı form (Artık Daire)
        if (!subscription.isPro && _wobbleController != null)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1400),
            curve: shouldShowButton ? Curves.easeOutBack : Curves.easeInCirc,
            // bottom: 124 (Açık - Nava daha uzak), 12 (Gizli - Navbar içinden çıkış)
            bottom: shouldShowButton ? 124 : 12, 
            right: 28,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: shouldShowButton ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOutBack,
              builder: (context, scaleFactor, child) {
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 600),
                  opacity: shouldShowButton ? 1.0 : 0.0, 
                  child: Transform.scale(
                    scale: scaleFactor,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1. Hareketli Su Damlası + AI Yıldızları (Animated Liquid & Stars)
                        AnimatedBuilder(
                          animation: _wobbleController!,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(50, 50),
                              painter: _WaterDropPainter(
                                color: activeColor,
                                morphFactor: scaleFactor,
                                wobbleValue: _wobbleController!.value,
                              ),
                            );
                          },
                        ),

                        // 2. Gizli GestureDetector
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              ProUpgradeSheet.show(context);
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: const SizedBox(width: 60, height: 60),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCenterFab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rotaryColor = ref.watch(rotaryColorProvider);
    final activeColor = isDark ? rotaryColor : AppColors.getAccentDeep(context, rotaryColor);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _openTransactionSheet();
      },
      child: Container(
        width: 60,
        height: 52,
        decoration: BoxDecoration(
          color: activeColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: isDark ? 0.4 : 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.add_rounded, 
            color: isDark ? Colors.black87 : Colors.white, 
            size: 32
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _currentIndex == index;
    
    final rotaryColor = ref.watch(rotaryColorProvider);
    final activeColor = isDark ? rotaryColor : AppColors.getAccentDeep(context, rotaryColor);
    
    final secondaryTextColor = AppColors.getTextSecondary(context);
    
    final color = isSelected ? activeColor : secondaryTextColor.withValues(alpha: 0.5);
    final icon = isSelected ? activeIcon : inactiveIcon;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkon Geçişi
            AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: isSelected ? 24 : 22,
              ),
            ),
            const SizedBox(height: 4),
            // İsim Altta ve Organik Geçişli
            AnimatedOpacity(
              duration: const Duration(milliseconds: 450),
              opacity: isSelected ? 1.0 : 0.0,
              curve: Curves.easeInOutCubic,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 450),
                offset: isSelected ? Offset.zero : const Offset(0, 0.4),
                curve: Curves.easeInOutCubic,
                child: Text(
                  label,
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Samsung/Google AI tarzı hareketli AI Yıldızları içeren Su Damlası Ressamı
class _WaterDropPainter extends CustomPainter {
  final Color color;
  final double morphFactor;
  final double wobbleValue;

  _WaterDropPainter({
    required this.color, 
    required this.morphFactor,
    required this.wobbleValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // 1. DERİN GÖLGE (Deep Soft Shadow)
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.3 * morphFactor)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center.translate(0, 6 * morphFactor), radius * morphFactor, shadowPaint);

    // 2. ANA CAM GÖVDESİ (Premium Glass Base)
    // 3 renkli geçiş ile daha fazla derinlik
    final glassPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(color, Colors.white, 0.2)!.withValues(alpha: 0.95),
          color.withValues(alpha: 1.0),
          Color.lerp(color, Colors.black, 0.15)!.withValues(alpha: 1.0),
        ],
        stops: const [0.0, 0.6, 1.0],
        center: const Alignment(-0.25, -0.25),
        radius: 0.9,
      ).createShader(Rect.fromCircle(center: center, radius: radius * morphFactor));
    canvas.drawCircle(center, radius * morphFactor, glassPaint);

    // 3. İÇ DERİNLİK (Inner Depth Shadow)
    final innerDepthPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.12 * morphFactor),
        ],
        stops: const [0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * morphFactor));
    canvas.drawCircle(center, radius * morphFactor, innerDepthPaint);

    // 4. PREMİUM KENAR IŞIĞI (Rim/Glass Light)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * morphFactor
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.5 * morphFactor),
          Colors.transparent,
          Colors.white.withValues(alpha: 0.1 * morphFactor),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius * morphFactor));
    canvas.drawCircle(center, radius * morphFactor * 0.97, rimPaint);

    // 5. ÜST YANSIMA (Top Reflection Layer)
    final reflectionPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.35 * morphFactor),
          Colors.white.withValues(alpha: 0.05 * morphFactor),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.45, 0.9],
      ).createShader(Rect.fromCircle(center: center, radius: radius * morphFactor));
    
    final reflectionPath = Path()
      ..addOval(Rect.fromCircle(center: center.translate(0, -radius * 0.15 * morphFactor), radius: radius * 0.75 * morphFactor));
    
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius * morphFactor)));
    canvas.drawPath(reflectionPath, reflectionPaint);
    canvas.restore();

    // 6. AI YILDIZLARI (Elegant and Subtle)
    if (morphFactor > 0.4) {
      _paintAIStars(canvas, center, size, morphFactor);
    }
  }

  void _paintAIStars(Canvas canvas, Offset center, Size size, double morph) {
    final t = wobbleValue * 2 * math.pi;
    final starColor = Colors.white.withValues(alpha: (morph - 0.4) * 1.5);
    
    // Daha az yıldız, daha küçük ve daha durgun
    _drawStar(canvas, center + Offset(0, -1), 12 * morph, t, starColor); // Ana Yıldız
    _drawStar(canvas, center + Offset(-10 * morph, 8 * morph), 6 * morph, t * 0.5, starColor.withValues(alpha: starColor.alpha * 0.6)); // Yan Yıldız
  }

  void _drawStar(Canvas canvas, Offset pos, double size, double rotation, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final pulseScale = 1.0 + 0.1 * math.sin(rotation);
    final s = size * pulseScale;
    
    final path = Path();
    path.moveTo(pos.dx, pos.dy - s);
    path.quadraticBezierTo(pos.dx + s * 0.15, pos.dy - s * 0.15, pos.dx + s, pos.dy);
    path.quadraticBezierTo(pos.dx + s * 0.15, pos.dy + s * 0.15, pos.dx, pos.dy + s);
    path.quadraticBezierTo(pos.dx - s * 0.15, pos.dy + s * 0.15, pos.dx - s, pos.dy);
    path.quadraticBezierTo(pos.dx - s * 0.15, pos.dy - s * 0.15, pos.dx, pos.dy - s);
    
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation * 0.1);
    canvas.translate(-pos.dx, -pos.dy);
    
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WaterDropPainter oldDelegate) => 
    oldDelegate.morphFactor != morphFactor || oldDelegate.wobbleValue != wobbleValue;
}
