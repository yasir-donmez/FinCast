import 'package:flutter/material.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/widgets/fluid_container.dart';
import '../../../../shared/widgets/fluid_sheet.dart';
import '../../../../shared/widgets/fluid_switch.dart';
import '../vaults_providers.dart';
import '../../../../l10n/app_localizations.dart';
import 'transaction_detail_sheet.dart';

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
    final screenHeight = MediaQuery.of(context).size.height;
    final sf = (screenHeight / 812.0).clamp(0.85, 1.0);

    String? periodLabel;
    if (tx.periodType != 0) {
      switch (tx.periodType) {
        case 1: periodLabel = l10n.weekly; break;
        case 2: periodLabel = l10n.monthly; break;
        case 3: periodLabel = l10n.yearly; break;
        case 4: periodLabel = l10n.every2Weeks; break;
        case 5: periodLabel = l10n.every3Weeks; break;
        case 6: periodLabel = l10n.every3Months; break;
        case 7: periodLabel = l10n.every6Months; break;
      }
    }

    final categoryName = localizedCategoryName(tx.categoryId, l10n) ?? l10n.all;
    final parentId = tx.categoryId?.split('_').take(2).join('_');
    final parentName = parentId != null ? localizedCategoryName(parentId, l10n) : null;
    final hasSubCategory = parentName != null && parentName != categoryName;

    final amountColor = tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context);
    final vaultCount = tx.groupIds.length;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: FluidContainer(
        padding: EdgeInsets.all(10 * sf), // Senin istediğin padding'e geri döndü
        borderRadius: 18 * sf,
        isGlass: true,
        color: tx.color.withValues(alpha: isDark ? 0.08 : 0.04),
        child: Stack(
          children: [
            Positioned(
              right: -15 * sf,
              top: -10 * sf,
              child: Opacity(
                opacity: isDark ? 0.05 : 0.03,
                child: Icon(tx.icon, size: 95 * sf, color: tx.color),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28 * sf, height: 28 * sf,
                      decoration: BoxDecoration(
                        color: tx.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8 * sf),
                      ),
                      child: Icon(tx.icon, color: tx.color, size: 15 * sf),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasSubCategory ? parentName ?? categoryName : categoryName,
                          style: TextStyle(
                            fontSize: 15 * sf,
                            fontWeight: FontWeight.w900,
                            color: AppColors.getTextPrimary(context),
                            letterSpacing: -0.5,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        if (hasSubCategory)
                          Text(
                            categoryName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9 * sf,
                              fontWeight: FontWeight.w800,
                              color: tx.color.withValues(alpha: 0.5),
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.right,
                          ),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: tx.minAmount != null && tx.maxAmount != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '₺${CurrencyUtils.formatAmount(tx.amount)}',
                                style: TextStyle(
                                  fontSize: 36 * sf,
                                  fontWeight: FontWeight.w900,
                                  color: amountColor,
                                  letterSpacing: -1.2,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₺${CurrencyUtils.formatAmount(tx.minAmount!)}',
                                  style: TextStyle(
                                    fontSize: 10.5 * sf,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white30 : Colors.black26,
                                  ),
                                ),
                                Text(' – ', style: TextStyle(fontSize: 10 * sf, color: isDark ? Colors.white24 : Colors.black12)),
                                Text(
                                  '₺${CurrencyUtils.formatAmount(tx.maxAmount!)}',
                                  style: TextStyle(
                                    fontSize: 10.5 * sf,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white30 : Colors.black26,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '₺${CurrencyUtils.formatAmount(tx.amount)}',
                            style: TextStyle(
                              fontSize: 44 * sf,
                              fontWeight: FontWeight.w900,
                              color: amountColor,
                              letterSpacing: -1.8,
                            ),
                          ),
                        ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tx.showOnDashboard ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          color: tx.showOnDashboard ? AppColors.getPrimary(context) : Colors.grey.withValues(alpha: 0.3),
                          size: 13 * sf,
                        ),
                        if (vaultCount > 0) ...[
                          SizedBox(width: 4 * sf),
                          Text(
                            '$vaultCount',
                            style: TextStyle(fontSize: 10 * sf, fontWeight: FontWeight.w900, color: Colors.grey.withValues(alpha: 0.6)),
                          ),
                          Icon(Icons.account_balance_wallet_rounded, size: 9 * sf, color: Colors.grey.withValues(alpha: 0.4)),
                        ],
                      ],
                    ),
                    if (periodLabel != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5 * sf, vertical: 2 * sf),
                        decoration: BoxDecoration(
                          color: amountColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5 * sf),
                        ),
                        child: Text(
                          periodLabel.toUpperCase(),
                          style: TextStyle(fontSize: 8 * sf, fontWeight: FontWeight.w900, color: amountColor, letterSpacing: 0.4),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void showTransactionActionMenu(
  BuildContext context, {
  required TransactionUI transaction,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  VoidCallback? onRemoveFromVault,
  required bool isInVault,
}) {
  FluidSheet.show(
    context: context,
    title: transaction.name,
    child: TransactionDetailSheet(
      transaction: transaction,
      onEdit: onEdit,
      onDelete: onDelete,
      onRemoveFromVault: onRemoveFromVault,
      isInVault: isInVault,
    ),
  );
}

Widget _buildActionItem({
  required BuildContext context,
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
  double scalingFactor = 1.0,
  Widget? trailing,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return GestureDetector(
    onTap: onTap,
    child: FluidContainer(
      padding: EdgeInsets.all(16 * scalingFactor),
      borderRadius: 24 * scalingFactor,
      isGlass: true,
      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.01),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10 * scalingFactor),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16 * scalingFactor),
            ),
            child: Icon(icon, color: color, size: 22 * scalingFactor),
          ),
          SizedBox(width: 16 * scalingFactor),
          Text(
            label,
            style: TextStyle(
              fontSize: 16 * scalingFactor,
              fontWeight: FontWeight.w800,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const Spacer(),
          if (trailing != null)
            trailing
          else
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.withValues(alpha: 0.5),
              size: 20 * scalingFactor,
            ),
        ],
      ),
    ),
  );
}
