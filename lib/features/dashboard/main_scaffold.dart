import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';
import '../transactions/add_transaction_sheet.dart';
import 'dashboard_screen.dart';
import '../optimization/optimization_screen.dart';
import '../profile/profile_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const AddTransactionSheet(), // "Artı" modali Vaults alanında ('Kasalar' yazısının yerine)
    const OptimizationScreen(), // Eski Vaults içeriği Analytics alanında
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor:
          AppColors.background, // Düz matte dark background (Image 2 gibi)
      body: SafeArea(bottom: false, child: _pages[_currentIndex]),

      // Skeuomorphic / Neumorphic Bottom Navigation Bar (Image 2'deki gibi)
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: AppColors.surface, // Alt bar zeminiyle aynı renk
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            // Üste doğru vuran hafif karanlık gölge (Embossed üst katman)
            BoxShadow(
              color: AppColors.darkShadow,
              offset: Offset(0, -4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _buildNavItem(
                1,
                Icons.account_balance_wallet_rounded,
                Icons.account_balance_wallet_outlined,
                'Vaults',
              ),
              _buildNavItem(
                2,
                Icons.bar_chart_rounded,
                Icons.bar_chart_outlined,
                'Analytics',
              ),
              _buildNavItem(
                3,
                Icons.person_rounded,
                Icons.person_outline_rounded,
                'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tıklanabilir Navigasyon İkonları (Image 2 - Aktif olan parlıyor ve çukurda)
  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    // Seçili değilse gri
    final color = isSelected
        ? AppColors.textPrimary
        : AppColors.textSecondary.withValues(alpha: 0.6);

    final icon = isSelected ? activeIcon : inactiveIcon;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
