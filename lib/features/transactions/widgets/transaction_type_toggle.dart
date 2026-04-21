import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/neu_container.dart';
import '../../../l10n/app_localizations.dart';

class TransactionTypeToggle extends StatelessWidget {
  final int tabIndex; // 0 = Gider, 1 = Gelir
  final ValueChanged<int> onTabChanged;

  const TransactionTypeToggle({
    super.key,
    required this.tabIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return NeuContainer(
      padding: const EdgeInsets.all(4),
      borderRadius: AppSizes.radiusRound,
      isInnerShadow: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: _buildTabBtn(
              context,
              l10n.expense.toUpperCase(),
              0,
              Icons.arrow_downward_rounded,
              AppColors.getError(context),
            ),
          ),
          Expanded(
            child: _buildTabBtn(
              context,
              l10n.income.toUpperCase(),
              1,
              Icons.arrow_upward_rounded,
              AppColors.getPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBtn(
    BuildContext context,
    String label,
    int index,
    IconData icon,
    Color activeColor,
  ) {
    final isActive = tabIndex == index;
    return GestureDetector(
      onTap: () {
        if (tabIndex != index) {
          onTabChanged(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.getSurface(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.getDarkShadow(context),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: AppColors.getLightShadow(context),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? activeColor
                    : AppColors.getTextSecondary(context),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? activeColor
                      : AppColors.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
