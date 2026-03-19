import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_constants.dart';
import '../transactions/add_transaction_sheet.dart';
import '../vaults/vaults_providers.dart';
import 'dashboard_screen.dart';
import '../vaults/vaults_screen.dart';
import '../optimization/optimization_screen.dart';
import '../profile/profile_screen.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const VaultsScreen(),
    const OptimizationScreen(),
    const ProfileScreen(),
  ];

  void _openTransactionSheet() {
    int? preselectedVaultId;
    if (_currentIndex == 1) {
      final selectedId = ref.read(selectedVaultProvider);
      if (selectedId != null && selectedId.startsWith('v_')) {
        preselectedVaultId = int.tryParse(selectedId.replaceFirst('v_', ''));
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTransactionSheet(initialVaultId: preselectedVaultId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = AppColors.getBackground(context);
    final surfaceColor = AppColors.getSurface(context);
    final darkShadowColor = AppColors.getDarkShadow(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: backgroundColor,
      body: SafeArea(bottom: false, child: _pages[_currentIndex]),
      bottomNavigationBar: Container(
        height: 88,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: darkShadowColor,
              offset: const Offset(0, -4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(child: _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, AppLocalizations.of(context)!.home)),
              Expanded(child: _buildNavItem(1, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, AppLocalizations.of(context)!.vaults)),
              _buildCenterFab(),
              Expanded(child: _buildNavItem(2, Icons.bar_chart_rounded, Icons.bar_chart_outlined, AppLocalizations.of(context)!.analysis)),
              Expanded(child: _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded, AppLocalizations.of(context)!.profile)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterFab() {
    return GestureDetector(
      onTap: _openTransactionSheet,
      child: Container(
        width: 64,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB388FF),
              Color(0xFF7C4DFF),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFFB388FF).withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 0),
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    final primaryTextColor = AppColors.getTextPrimary(context);
    final secondaryTextColor = AppColors.getTextSecondary(context);
    
    final color = isSelected ? primaryTextColor : secondaryTextColor.withValues(alpha: 0.6);
    final icon = isSelected ? activeIcon : inactiveIcon;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              child: Icon(
                icon,
                key: ValueKey<IconData>(icon),
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                    letterSpacing: 0.2,
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
