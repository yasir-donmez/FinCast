import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/utils/currency_utils.dart';
import '../vaults_providers.dart';

class GroupCard extends StatefulWidget {
  final TransactionGroup group;
  final List<MockTransaction> transactions;
  final bool isEditMode;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const GroupCard({
    super.key,
    required this.group,
    required this.transactions,
    this.isEditMode = false,
    this.onTap,
    this.onDelete,
  });

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    final duration = 300 + Random().nextInt(200);
    _shakeController = AnimationController(vsync: this, duration: Duration(milliseconds: duration));
    _shakeAnimation = Tween<double>(begin: -0.025, end: 0.025).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
    if (widget.isEditMode) _shakeController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant GroupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditMode && !oldWidget.isEditMode) {
      _shakeController.repeat(reverse: true);
    } else if (!widget.isEditMode && oldWidget.isEditMode) {
      _shakeController.stop();
      _shakeController.reset();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txList = widget.transactions;
    double totalAmount = 0;
    double totalMin = 0;
    double totalMax = 0;
    bool hasPill = false;

    for (final tx in txList) {
      final amt = tx.isIncome ? tx.amount : -tx.amount;
      totalAmount += amt;
      if (tx.minAmount != null || tx.maxAmount != null) hasPill = true;
      final mn = tx.isIncome ? (tx.minAmount ?? tx.amount) : -(tx.maxAmount ?? tx.amount);
      final mx = tx.isIncome ? (tx.maxAmount ?? tx.amount) : -(tx.minAmount ?? tx.amount);
      totalMin += mn;
      totalMax += mx;
    }

    final glowColor = txList.isNotEmpty ? txList.first.color : AppColors.getTextPrimary(context);
    final bool isPositive = totalAmount >= 0;

    Widget card = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
          boxShadow: [
            BoxShadow(color: AppColors.getDarkShadow(context), offset: const Offset(4, 4), blurRadius: 8),
            BoxShadow(color: AppColors.getLightShadow(context), offset: const Offset(-3, -3), blurRadius: 8),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: SizedBox(
                width: 76,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.group.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.getTextPrimary(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: glowColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: glowColor.withValues(alpha: 0.2), width: 0.5)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.layers_rounded, size: 8, color: glowColor), const SizedBox(width: 3), Text('${txList.length}', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: glowColor))]),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: glowColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.25), blurRadius: 15, spreadRadius: -2)]),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(4, (i) {
                      if (i < txList.length) {
                        final tx = txList[i];
                        return Container(decoration: BoxDecoration(color: tx.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Icon(tx.icon, color: tx.color, size: 12));
                      }
                      return Container(decoration: BoxDecoration(color: AppColors.getInnerSurface(context), borderRadius: BorderRadius.circular(4)));
                    }),
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(fit: BoxFit.scaleDown, child: Text('₺${CurrencyUtils.formatAmount(totalAmount.abs())}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isPositive ? AppColors.getIncome(context) : AppColors.getExpense(context)))),
              ],
            ),
            if (hasPill)
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
                          Text(CurrencyUtils.formatAmount(totalMin.abs()), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.getExpense(context))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: Text('~', style: TextStyle(fontSize: 9, color: AppColors.getTextSecondary(context).withValues(alpha: 0.5)))),
                          Icon(Icons.arrow_upward_rounded, size: 8, color: AppColors.getIncome(context)),
                          const SizedBox(width: 1),
                          Text(CurrencyUtils.formatAmount(totalMax.abs()), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.getIncome(context))),
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

    if (widget.isEditMode) {
      card = Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(animation: _shakeAnimation, builder: (context, child) => Transform.rotate(angle: _shakeAnimation.value, child: child), child: card),
          Positioned(top: -6, right: -6, child: Container(width: 26, height: 26, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 4)]), child: const Icon(Icons.settings_suggest_rounded, size: 16, color: Colors.white))),
        ],
      );
    }
    return card;
  }
}
