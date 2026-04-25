import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/precision_card.dart';
import '../../../l10n/app_localizations.dart';

class TransactionAmountInput extends StatelessWidget {
  final bool isFlexibleAmount;
  final TextEditingController amountController;
  final TextEditingController minController;
  final TextEditingController maxController;
  final FocusNode amountFocusNode;

  const TransactionAmountInput({
    super.key,
    required this.isFlexibleAmount,
    required this.amountController,
    required this.minController,
    required this.maxController,
    required this.amountFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: isFlexibleAmount
          ? _buildFlexibleAmountDisplay(context)
          : _buildSingleAmountDisplay(context),
    );
  }

  Widget _buildSingleAmountDisplay(BuildContext context) {
    return Container(
      key: const ValueKey('single_amount'),
      height: 100,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
      child: TextFormField(
        controller: amountController,
        focusNode: amountFocusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w900,
          color: AppColors.getTextPrimary(context),
          letterSpacing: -2.0,
        ),
        cursorColor: AppColors.getPrimary(context),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "0",
          hintStyle: TextStyle(
            color: AppColors.getTextSecondary(context).withValues(alpha: 0.2),
          ),
          prefixText: "₺",
          prefixStyle: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: AppColors.getPrimary(context).withValues(alpha: 0.5),
            letterSpacing: -1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildFlexibleAmountDisplay(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const ValueKey('flex_amount'),
      height: 100,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildFlexBox(context, l10n.minimum, minController)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              "-",
              style: TextStyle(
                fontSize: 24,
                color: AppColors.getTextSecondary(context).withValues(alpha: 0.3),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: _buildFlexBox(context, l10n.maximum, maxController)),
        ],
      ),
    );
  }

  Widget _buildFlexBox(
    BuildContext context,
    String label,
    TextEditingController controller,
  ) {
    return PrecisionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: AppColors.getPrimary(context).withValues(alpha: 0.7),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.getTextPrimary(context),
              letterSpacing: -0.5,
            ),
            cursorColor: AppColors.getPrimary(context),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: "0",
              hintStyle: TextStyle(
                color: AppColors.getTextSecondary(context).withValues(alpha: 0.2),
              ),
              prefixText: "₺ ",
              prefixStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.getPrimary(context).withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

