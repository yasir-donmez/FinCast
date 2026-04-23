import 'package:flutter/material.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/widgets/fluid_container.dart';
import '../../../../shared/widgets/fluid_sheet.dart';
import '../../../../shared/widgets/fluid_switch.dart';
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
    // Alt kategori: categoryId'nin son kısmı ana kategoriden farklıysa göster
    final parentId = tx.categoryId?.split('_').take(2).join('_');
    final parentName = parentId != null ? localizedCategoryName(parentId, l10n) : null;
    final hasSubCategory = parentName != null && parentName != categoryName;
    
    final amountColor = tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context);
    final vaultCount = tx.groupIds.length;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: FluidContainer(
        padding: EdgeInsets.all(10 * sf),
        borderRadius: 18 * sf,
        isGlass: true,
        color: tx.color.withValues(alpha: isDark ? 0.08 : 0.04),
        child: Stack(
          children: [
            // Arka plan simgesi (büyük, silik)
            Positioned(
              right: -8 * sf,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  tx.icon,
                  size: 80 * sf,
                  color: tx.color.withValues(alpha: isDark ? 0.06 : 0.04),
                ),
              ),
            ),
            // Ana içerik
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            // ━━━ 1. SATIR: İKON + KATEGORİ/ALT KATEGORİ (SAĞDA) ━━━
            Row(
              children: [
                // Kategori İkonu
                Container(
                  width: 38 * sf, height: 38 * sf,
                  decoration: BoxDecoration(
                    color: tx.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12 * sf),
                  ),
                  child: Icon(tx.icon, color: tx.color, size: 20 * sf),
                ),
                const Spacer(),
                // Kategori + Alt Kategori (Sağa Hizalı)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasSubCategory ? parentName ?? categoryName : categoryName,
                      style: TextStyle(
                        fontSize: 15 * sf,
                        fontWeight: FontWeight.w800,
                        color: AppColors.getTextPrimary(context),
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasSubCategory) ...[
                      SizedBox(height: 1 * sf),
                      Text(
                        categoryName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10 * sf,
                          fontWeight: FontWeight.w800,
                          color: tx.color.withValues(alpha: 0.5),
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // ━━━ 2. SATIR: TUTARLAR (Genişletilmiş) ━━━
            Expanded(
              child: Center(
                child: tx.minAmount != null && tx.maxAmount != null
                  // Min/Max VARSA: İkiye bölünmüş görünüm
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Üst: Ortalama Tutar
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '₺${CurrencyUtils.formatAmount(tx.amount)}',
                            style: TextStyle(
                              fontSize: 32 * sf,
                              fontWeight: FontWeight.w900,
                              color: amountColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        SizedBox(height: 4 * sf),
                        // Alt: Min – Max Aralığı
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₺${CurrencyUtils.formatAmount(tx.minAmount!)}',
                              style: TextStyle(
                                fontSize: 12 * sf,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white54 : Colors.black38,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4 * sf),
                              child: Text(
                                '–',
                                style: TextStyle(
                                  fontSize: 12 * sf,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white30 : Colors.black26,
                                ),
                              ),
                            ),
                            Text(
                              '₺${CurrencyUtils.formatAmount(tx.maxAmount!)}',
                              style: TextStyle(
                                fontSize: 12 * sf,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white54 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  // Min/Max YOKSA: Tek büyük tutar, tam ortada
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '₺${CurrencyUtils.formatAmount(tx.amount)}',
                        style: TextStyle(
                          fontSize: 36 * sf,
                          fontWeight: FontWeight.w900,
                          color: amountColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
              ),
            ),

            // ━━━ 3. SATIR: DASHBOARD + KASA + PERİYOT ━━━
            Row(
              children: [
                // Dashboard görünürlük ikonu (göz)
                Icon(
                  tx.showOnDashboard ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: tx.showOnDashboard 
                      ? AppColors.getPrimary(context) 
                      : Colors.grey.withValues(alpha: 0.3),
                  size: 18 * sf,
                ),
                SizedBox(width: 6 * sf),
                // Kasa noktaları
                if (vaultCount > 0) ...[
                  ...List.generate(vaultCount.clamp(0, 5), (_) => Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Container(
                      width: 5 * sf, height: 5 * sf,
                      decoration: BoxDecoration(
                        color: AppColors.getPrimary(context).withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )),
                  SizedBox(width: 2 * sf),
                  Text(
                    '$vaultCount ${l10n.vaults.toLowerCase()}',
                    style: TextStyle(
                      fontSize: 11 * sf,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                  ),
                ],
                const Spacer(),
                // Periyot Badge (Sağa Hizalı)
                if (periodLabel != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5 * sf, vertical: 2 * sf),
                    decoration: BoxDecoration(
                      color: amountColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4 * sf),
                    ),
                    child: Text(
                      periodLabel.toUpperCase(),
                      style: TextStyle(fontSize: 9 * sf, fontWeight: FontWeight.w900, color: amountColor),
                    ),
                  ),
              ],
            ),
          ],  // Column children
        ),  // Column
          ],  // Stack children
        ),  // Stack
      ),  // FluidContainer
    );  // GestureDetector
  }
}

void showTransactionActionMenu(BuildContext context, {
  required String name, 
  required VoidCallback onEdit, 
  required VoidCallback onDelete, 
  VoidCallback? onRemoveFromVault,
  required bool isInVault,
  bool? showOnDashboard,
  Function(bool)? onToggleDashboard,
}) {
  final l10n = AppLocalizations.of(context)!;
  bool currentShowOnDashboard = showOnDashboard ?? false;

  final screenHeight = MediaQuery.of(context).size.height;
  final scalingFactor = (screenHeight / 812.0).clamp(0.85, 1.0);

  FluidSheet.show(
    context: context,
    title: name,
    child: StatefulBuilder(
      builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionItem(
              context: context,
              icon: Icons.edit_note_rounded,
              label: l10n.edit,
              color: AppColors.getPrimary(context),
              scalingFactor: scalingFactor,
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),

            SizedBox(height: 12 * scalingFactor),

            if (onToggleDashboard != null)
              _buildActionItem(
                context: context,
                icon: currentShowOnDashboard ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                label: currentShowOnDashboard ? 'Ana Sayfadan Kaldır' : 'Ana Sayfada Göster',
                color: currentShowOnDashboard ? Colors.blue : Colors.grey,
                scalingFactor: scalingFactor,
                trailing: FluidSwitch(
                  value: currentShowOnDashboard,
                  activeColor: Colors.blue,
                  activeIcon: Icons.visibility_rounded,
                  inactiveIcon: Icons.visibility_off_rounded,
                  scalingFactor: 0.8 * scalingFactor,
                  onChanged: (val) {
                    setState(() => currentShowOnDashboard = val);
                    onToggleDashboard(val);
                  },
                ),
                onTap: () {
                  final newVal = !currentShowOnDashboard;
                  setState(() => currentShowOnDashboard = newVal);
                  onToggleDashboard(newVal);
                },
              ),
            
            if (isInVault && onRemoveFromVault != null) ...[
              SizedBox(height: 12 * scalingFactor),
              _buildActionItem(
                context: context,
                icon: Icons.outbox_rounded,
                label: l10n.removeFromVault,
                color: Colors.orange,
                scalingFactor: scalingFactor,
                onTap: () {
                  Navigator.pop(context);
                  onRemoveFromVault();
                },
              ),
            ],

            SizedBox(height: 12 * scalingFactor),
            
            _buildActionItem(
              context: context,
              icon: Icons.delete_sweep_rounded,
              label: l10n.permanentDelete,
              color: AppColors.error,
              scalingFactor: scalingFactor,
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            SizedBox(height: 16 * scalingFactor),
          ],
        );
      }
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
              color: AppColors.getTextPrimary(context)
            )
          ),
          const Spacer(),
          if (trailing != null) 
            trailing
          else
            Icon(Icons.chevron_right_rounded, color: Colors.grey.withValues(alpha: 0.5), size: 20 * scalingFactor),
        ],
      ),
    ),
  );
}
