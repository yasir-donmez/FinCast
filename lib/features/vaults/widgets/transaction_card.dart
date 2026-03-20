import 'package:flutter/material.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../shared/widgets/fluid_container.dart';
import '../vaults_providers.dart';
import '../../../../l10n/app_localizations.dart';

String? localizedCategoryName(String? categoryId, AppLocalizations l10n) {
  if (categoryId == null) return null;
  switch (categoryId) {
    case 'exp_grocery': return l10n.grocery;
    case 'exp_grocery_food': return l10n.food;
    case 'exp_grocery_cleaning': return l10n.cleaning;
    case 'exp_grocery_personal': return l10n.personalCare;
    case 'exp_dining': return l10n.dining;
    case 'exp_dining_restaurant': return l10n.restaurant;
    case 'exp_dining_fastfood': return l10n.fastFood;
    case 'exp_dining_cafe': return l10n.cafe;
    case 'exp_rent': return l10n.rent;
    case 'exp_rent_home': return l10n.homeRent;
    case 'exp_rent_office': return l10n.workspace;
    case 'exp_bill': return l10n.bill;
    case 'exp_bill_electricity': return l10n.electricity;
    case 'exp_bill_water': return l10n.water;
    case 'exp_fun': return l10n.entertainment;
    case 'exp_trans': return l10n.transportation;
    case 'exp_sub': return l10n.subscription;
    case 'exp_health': return l10n.health;
    case 'inc_salary': return l10n.salary;
    case 'inc_salary_main': return l10n.mainSalary;
    case 'inc_salary_bonus': return l10n.bonus;
    case 'inc_extra': return l10n.extraIncome;
    default: return null;
  }
}

class TransactionCard extends StatelessWidget {
  final TransactionUI transaction;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onDelete,
    this.onEdit,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String? periodLabel;
    if (tx.periodType != 0) {
      switch (tx.periodType) {
        case 1: periodLabel = 'HAFTALIK'; break;
        case 2: periodLabel = 'AYLIK'; break;
        case 3: periodLabel = 'YILLIK'; break;
      }
    }

    final displayName = localizedCategoryName(tx.categoryId, l10n) ?? tx.name;
    final amountColor = tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: FluidContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 28,
        isGlass: true,
        color: tx.color.withValues(alpha: isDark ? 0.08 : 0.04),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: tx.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(tx.icon, color: tx.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.toUpperCase(), 
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.withValues(alpha: 0.7), letterSpacing: 1.5),
                        maxLines: 1, overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tx.name, 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(context)),
                        maxLines: 1, overflow: TextOverflow.ellipsis
                      ),
                    ],
                  ),
                ),
                if (periodLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: amountColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(periodLabel, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: amountColor)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tx.minAmount != null && tx.maxAmount != null) ...[
                      Row(
                        children: [
                          Icon(Icons.unfold_more_rounded, size: 10, color: Colors.grey.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            '₺${CurrencyUtils.formatAmount(tx.minAmount!)} - ₺${CurrencyUtils.formatAmount(tx.maxAmount!)}',
                            style: TextStyle(fontSize: 10, color: Colors.grey.withValues(alpha: 0.8), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '₺${CurrencyUtils.formatAmount(tx.amount)}', 
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: amountColor, letterSpacing: -1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void showTransactionActionMenu(BuildContext context, {required String name, required VoidCallback onEdit, required VoidCallback onDelete, required bool isInVault}) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 32), decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
          _buildActionItem(context, Icons.edit_note_rounded, l10n.edit, AppColors.primary, onEdit),
          const SizedBox(height: 12),
          _buildActionItem(
            context, 
            isInVault ? Icons.logout_rounded : Icons.delete_sweep_rounded, 
            isInVault ? l10n.removeFromVault : l10n.permanentDelete, 
            AppColors.error, 
            onDelete
          ),
        ],
      ),
    ),
  );
}

Widget _buildActionItem(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: () { Navigator.pop(context); onTap(); },
    child: FluidContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      isGlass: true,
      color: color.withValues(alpha: 0.05),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(context))),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    ),
  );
}
