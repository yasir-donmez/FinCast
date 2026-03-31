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
import '../../shared/widgets/membership_orb.dart';

import 'dashboard_scroll_provider.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}
class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;
  bool _isProButtonVisible = true;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const VaultsScreen(),
    const OptimizationScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardScrollProvider).addListener(_onScroll);
    });
  }

  @override
  void dispose() {
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
        if (!subscription.isPro)
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
                        Hero(
                          tag: 'pro_orb',
                          child: MembershipOrb(
                            color: activeColor,
                            size: 50,
                            morphFactor: scaleFactor,
                          ),
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
