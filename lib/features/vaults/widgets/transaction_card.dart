import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/widgets/fluid_container.dart';
import '../../../../shared/widgets/fluid_sheet.dart';
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
        case 1: periodLabel = l10n.weekly; break;
        case 2: periodLabel = l10n.monthly; break;
        case 3: periodLabel = l10n.yearly; break;
        case 4: periodLabel = l10n.every2Weeks; break;
        case 5: periodLabel = l10n.every3Weeks; break;
        case 6: periodLabel = l10n.every3Months; break;
        case 7: periodLabel = l10n.every6Months; break;
      }
    }

    // Üst Model (Kategori) ve Alt Model (İsim) Ayrımı
    final mainModelName = localizedCategoryName(tx.categoryId, l10n) ?? l10n.all.toUpperCase();
    final subModelName = tx.name;
    
    final amountColor = tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: FluidContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 32,
        isGlass: true,
        color: tx.color.withValues(alpha: isDark ? 0.08 : 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Üst Bölüm: İkon ve Periyot Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: tx.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(tx.icon, color: tx.color, size: 22),
                ),
                if (periodLabel != null)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: amountColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        periodLabel.toUpperCase(), 
                        style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: amountColor, letterSpacing: 0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Orta Bölüm: Başlık Hiyerarşisi (Ana Model / Alt Model)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mainModelName.toUpperCase(), 
                      style: TextStyle(
                        fontSize: 8, 
                        fontWeight: FontWeight.w900, 
                        color: tx.color.withValues(alpha: 0.6), 
                        letterSpacing: 1.5
                      ),
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subModelName, 
                      style: TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.bold, 
                        color: AppColors.getTextPrimary(context),
                        height: 1.15,
                        letterSpacing: -0.2
                      ),
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis
                    ),
                  ],
                ),
              ),
            ),
            
            // Alt Bölüm: Tutar ve Belirgin Range
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tx.minAmount != null && tx.maxAmount != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: isDark ? 0.1 : 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.unfold_more_rounded, size: 12, color: amountColor.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          '₺${CurrencyUtils.formatAmount(tx.minAmount!)} - ₺${CurrencyUtils.formatAmount(tx.maxAmount!)}',
                          style: TextStyle(
                            fontSize: 10.5, 
                            color: isDark ? Colors.white70 : Colors.black87, 
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₺${CurrencyUtils.formatAmount(tx.amount)}', 
                      style: TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.w900, 
                        color: amountColor, 
                        letterSpacing: -1.5
                      ),
                    ),
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

void showTransactionActionMenu(BuildContext context, {
  required String name, 
  required VoidCallback onEdit, 
  required VoidCallback onDelete, 
  VoidCallback? onRemoveFromVault,
  required bool isInVault
}) {
  final l10n = AppLocalizations.of(context)!;

  FluidSheet.show(
    context: context,
    title: name,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. DÜZENLE
        _buildActionItem(
          context: context,
          icon: Icons.edit_note_rounded,
          label: l10n.edit,
          color: AppColors.getPrimary(context),
          onTap: () {
            Navigator.pop(context);
            onEdit();
          },
        ),
        
        // 2. KASADAN ÇIKAR (Sadece kasa içindeyse)
        if (isInVault && onRemoveFromVault != null) ...[
          const SizedBox(height: 12),
          _buildActionItem(
            context: context,
            icon: Icons.outbox_rounded,
            label: l10n.removeFromVault,
            color: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              onRemoveFromVault();
            },
          ),
        ],

        const SizedBox(height: 12),
        
        // 3. TAMAMEN SİL (Her zaman kırmızı ve tehlikeli)
        _buildActionItem(
          context: context,
          icon: Icons.delete_sweep_rounded,
          label: l10n.permanentDelete,
          color: AppColors.error,
          onTap: () {
            Navigator.pop(context);
            onDelete();
          },
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}

Widget _buildActionItem({
  required BuildContext context,
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return GestureDetector(
    onTap: onTap,
    child: FluidContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      isGlass: true,
      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.01),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Text(
            label, 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w800, 
              color: AppColors.getTextPrimary(context)
            )
          ),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.withValues(alpha: 0.5), size: 20),
        ],
      ),
    ),
  );
}
