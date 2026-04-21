import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/neu_container.dart';
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
      duration: const Duration(milliseconds: 300),
      child: isFlexibleAmount
          ? _buildFlexibleAmountDisplay(context)
          : _buildSingleAmountDisplay(context),
    );
  }

  Widget _buildSingleAmountDisplay(BuildContext context) {
    return Container(
      key: const ValueKey('single_amount'),
      height: 90,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
      child: TextFormField(
        controller: amountController,
        focusNode: amountFocusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppColors.getTextPrimary(context),
          letterSpacing: -1.0,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "0",
          hintStyle: TextStyle(
            color: AppColors.getTextSecondary(context).withValues(alpha: 0.3),
          ),
          prefixText: "₺",
          prefixStyle: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextSecondary(context),
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
      height: 90,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildFlexBox(context, l10n.minimum, minController)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "-",
              style: TextStyle(
                fontSize: 24,
                color: AppColors.getTextSecondary(context),
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
    return NeuContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      isInnerShadow: true,
      borderRadius: AppSizes.radiusLarge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.getPrimary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(context),
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: "0",
              hintStyle: TextStyle(
                color: AppColors.getTextSecondary(context).withValues(alpha: 0.3),
              ),
              prefixText: "₺ ",
              prefixStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
