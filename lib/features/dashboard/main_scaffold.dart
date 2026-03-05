import 'package:flutter/material.dart';
import '../../core/theme/app_constants.dart';
import '../transactions/add_transaction_sheet.dart';
import 'dashboard_screen.dart';
import '../vaults/vaults_screen.dart';
import '../optimization/optimization_screen.dart';
import '../profile/profile_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // 4 gerçek sayfa (FAB hariç)
  final List<Widget> _pages = [
    const DashboardScreen(), // 0 = Home
    const VaultsScreen(), // 1 = Kasalar
    const OptimizationScreen(), // 2 = Analiz
    const ProfileScreen(), // 3 = Profil
  ];

  // İşlem ekle bottom sheet'ini açar (Merkez FAB)
  void _openTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: _pages[_currentIndex]),

      // 5 Elemanlı Neumorphic Bottom Nav Bar (Merkez FAB ile)
      bottomNavigationBar: Container(
        height: 88,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkShadow,
              offset: Offset(0, -4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              // 2. Kasalar (Vaults)
              _buildNavItem(
                1,
                Icons.account_balance_wallet_rounded,
                Icons.account_balance_wallet_outlined,
                'Kasalar',
              ),
              // 3. Merkez FAB (+İşlem Ekle)
              _buildCenterFab(),
              // 4. Analiz
              _buildNavItem(
                2,
                Icons.bar_chart_rounded,
                Icons.bar_chart_outlined,
                'Analiz',
              ),
              // 5. Profil
              _buildNavItem(
                3,
                Icons.person_rounded,
                Icons.person_outline_rounded,
                'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Merkez FAB (Mor gradient, gölgeli, referans görseldeki gibi)
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
              Color(0xFFB388FF), // Açık mor
              Color(0xFF7C4DFF), // Koyu mor
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

  // Tıklanabilir Nav İkon (4 gerçek sayfa için)
  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? AppColors.textPrimary
        : AppColors.textSecondary.withValues(alpha: 0.6);
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
