import 'package:flutter/material.dart';
import '../../../../core/theme/app_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../shared/widgets/neu_container.dart';
import '../vaults_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// Verilen categoryId için yerelleştirilmiş kategori adını döndürür.
/// Eşleşme bulunamazsa null döner.
String? localizedCategoryName(String? categoryId, AppLocalizations l10n) {
  if (categoryId == null) return null;
  switch (categoryId) {
    // Expense
    case 'exp_grocery': return l10n.grocery;
    case 'exp_grocery_food': return l10n.food;
    case 'exp_grocery_cleaning': return l10n.cleaning;
    case 'exp_grocery_personal': return l10n.personalCare;
    case 'exp_dining': return l10n.dining;
    case 'exp_dining_restaurant': return l10n.restaurant;
    case 'exp_dining_fastfood': return l10n.fastFood;
    case 'exp_dining_cafe': return l10n.cafe;
    case 'exp_dining_delivery': return l10n.delivery;
    case 'exp_rent': return l10n.rent;
    case 'exp_rent_home': return l10n.homeRent;
    case 'exp_rent_office': return l10n.workspace;
    case 'exp_rent_storage': return l10n.storage;
    case 'exp_bill': return l10n.bill;
    case 'exp_bill_electricity': return l10n.electricity;
    case 'exp_bill_water': return l10n.water;
    case 'exp_bill_gas': return l10n.gas;
    case 'exp_bill_internet': return l10n.internet;
    case 'exp_bill_phone': return l10n.phone;
    case 'exp_fun': return l10n.entertainment;
    case 'exp_fun_cinema': return l10n.cinema;
    case 'exp_fun_concert': return l10n.concert;
    case 'exp_fun_game': return l10n.game;
    case 'exp_fun_event': return l10n.event;
    case 'exp_sub': return l10n.subscription;
    case 'exp_sub_stream': return l10n.streaming;
    case 'exp_sub_music': return l10n.musicSubscription;
    case 'exp_sub_software': return l10n.software;
    case 'exp_sub_gym': return l10n.gym;
    case 'exp_health': return l10n.health;
    case 'exp_health_doctor': return l10n.doctor;
    case 'exp_health_medicine': return l10n.medicine;
    case 'exp_health_surgery': return l10n.surgery;
    case 'exp_health_dentist': return l10n.dentist;
    case 'exp_trans': return l10n.transportation;
    case 'exp_trans_taxi': return l10n.taxi;
    case 'exp_trans_bus': return l10n.bus;
    case 'exp_trans_train': return l10n.train;
    case 'exp_trans_flight': return l10n.flight;
    case 'exp_trans_fuel': return l10n.fuel;
    case 'exp_cloth': return l10n.clothing;
    case 'exp_cloth_daily': return l10n.dailyWear;
    case 'exp_cloth_shoes': return l10n.shoes;
    case 'exp_cloth_acc': return l10n.accessory;
    case 'exp_edu': return l10n.education;
    case 'exp_edu_course': return l10n.course;
    case 'exp_edu_book': return l10n.book;
    case 'exp_edu_school': return l10n.school;
    case 'exp_debt': return l10n.debtPayment;
    case 'exp_debt_credit_card': return l10n.creditCard;
    case 'exp_debt_loan': return l10n.loan;
    case 'exp_debt_personal': return l10n.personalDebt;
    case 'exp_other': return l10n.other;
    // Income
    case 'inc_salary': return l10n.salary;
    case 'inc_salary_main': return l10n.mainSalary;
    case 'inc_salary_bonus': return l10n.bonus;
    case 'inc_salary_dividend': return l10n.dividend;
    case 'inc_extra': return l10n.extraIncome;
    case 'inc_extra_freelance': return l10n.freelance;
    case 'inc_extra_parttime': return l10n.partTime;
    case 'inc_extra_commission': return l10n.commission;
    case 'inc_invest': return l10n.investmentReturn;
    case 'inc_invest_stock': return l10n.stock;
    case 'inc_invest_crypto': return l10n.crypto;
    case 'inc_invest_interest': return l10n.interest;
    case 'inc_scholarship': return l10n.scholarshipLoan;
    case 'inc_scholarship_award': return l10n.scholarship;
    case 'inc_scholarship_loan': return l10n.credit;
    case 'inc_sale': return l10n.sale;
    case 'inc_sale_online': return l10n.onlineSale;
    case 'inc_sale_physical': return l10n.physicalSale;
    case 'inc_rent': return l10n.rentalIncome;
    case 'inc_rent_home': return l10n.home;
    case 'inc_rent_office': return l10n.officeIncome;
    case 'inc_gift': return l10n.gift;
    case 'inc_other': return l10n.other;
    default: return null;
  }
}

class TransactionCard extends StatelessWidget {
  final MockTransaction transaction;
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
    String? periodLabel;
    IconData? periodIcon;

    if (tx.periodType != 0) {
      periodIcon = Icons.update_rounded;
      final count = (tx.remainingInstallments != null && tx.remainingInstallments! > 0) ? tx.remainingInstallments.toString() : '';
      switch (tx.periodType) {
        case 1: periodLabel = 'H$count'; break;
        case 4: periodLabel = '2H$count'; break;
        case 5: periodLabel = '3H$count'; break;
        case 2: periodLabel = 'A$count'; break;
        case 6: periodLabel = '3A$count'; break;
        case 7: periodLabel = '6A$count'; break;
        case 3: periodLabel = 'Y$count'; break;
        case 8: periodLabel = 'G$count'; break;
        case 9: periodLabel = '2G$count'; break;
        case 10: periodLabel = '3G$count'; break;
      }
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: NeuContainer(
        padding: const EdgeInsets.all(8.0),
        borderRadius: AppSizes.radiusDefault,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  Expanded(
                    child: Builder(builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      final displayName = localizedCategoryName(tx.categoryId, l10n) ?? tx.name;
                      return SizedBox(
                        height: 16,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextPrimary(context),
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (periodLabel != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: tx.isIncome ? AppColors.getIncome(context).withValues(alpha: 0.1) : AppColors.getExpense(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: tx.isIncome ? AppColors.getIncome(context).withValues(alpha: 0.2) : AppColors.getExpense(context).withValues(alpha: 0.2), width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (periodIcon != null) ...[Icon(periodIcon, size: 8, color: tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context)), const SizedBox(width: 2)],
                          Text(periodLabel, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tx.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: tx.color.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: -2)],
                  ),
                  child: Icon(tx.icon, color: tx.color, size: 22),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₺${CurrencyUtils.formatAmount(tx.amount)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: tx.isIncome ? AppColors.getIncome(context) : AppColors.getExpense(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (tx.minAmount != null && tx.maxAmount != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.getBackground(context), width: 1),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_downward_rounded, size: 8, color: AppColors.getExpense(context)),
                          const SizedBox(width: 1),
                          Text(CurrencyUtils.formatAmount(tx.minAmount!), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.getExpense(context))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: Text('~', style: TextStyle(fontSize: 9, color: AppColors.getTextSecondary(context).withValues(alpha: 0.5)))),
                          Icon(Icons.arrow_upward_rounded, size: 8, color: AppColors.getIncome(context)),
                          const SizedBox(width: 1),
                          Text(CurrencyUtils.formatAmount(tx.maxAmount!), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.getIncome(context))),
                        ],
                      ),
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

void showTransactionActionMenu(BuildContext context, {required String name, required VoidCallback onEdit, required VoidCallback onDelete, required bool isInVault}) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.getSurface(context), borderRadius: BorderRadius.circular(AppSizes.radiusLarge), boxShadow: [BoxShadow(color: AppColors.getDarkShadow(context), blurRadius: 20, offset: const Offset(0, -4))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.getDarkShadow(context).withValues(alpha: 0.3)))),
            child: Row(children: [const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20), const SizedBox(width: 10), Expanded(child: Text(name, style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 15, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis))]),
          ),
          ListTile(
            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle), child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18)),
            title: Text(l10n.edit, style: TextStyle(color: AppColors.getTextPrimary(context), fontWeight: FontWeight.w500)),
            subtitle: Text(l10n.editTransactionDesc, style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 12)),
            onTap: () { Navigator.pop(ctx); onEdit(); },
          ),
          ListTile(
            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(isInVault ? Icons.logout_rounded : Icons.delete_outline_rounded, color: AppColors.error, size: 18)),
            title: Text(isInVault ? l10n.removeFromVault : l10n.permanentDelete, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500)),
            subtitle: Text(isInVault ? l10n.removeFromVaultDesc : l10n.permanentDeleteDesc, style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 12)),
            onTap: () { Navigator.pop(ctx); onDelete(); },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
