import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/precision_input.dart';
import '../../../l10n/app_localizations.dart';

class TransactionAmountInput extends StatelessWidget {
  final bool isFlexibleAmount;
  final String currency;
  final TextEditingController amountController;
  final TextEditingController minController;
  final TextEditingController maxController;
  final FocusNode amountFocusNode;

  const TransactionAmountInput({
    super.key,
    required this.isFlexibleAmount,
    required this.currency,
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
      child: PrecisionInput(
        controller: amountController,
        hintText: "0",
        icon: Icons.attach_money_rounded,
        keyboardType: TextInputType.number,
        inputFormatters: [_ThousandsSeparatorFormatter()],
        textAlign: TextAlign.center,
        fontSize: 56,
        suffixText: currency,
        showBackground: false,
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
    return Column(
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
        PrecisionInput(
          controller: controller,
          hintText: "0",
          icon: Icons.attach_money_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [_ThousandsSeparatorFormatter()],
          textAlign: TextAlign.center,
          fontSize: 24,
          suffixText: currency,
          showBackground: false,
        ),
      ],
    );
  }
}

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    // Sadece sayıları al
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return newValue.copyWith(text: '');

    // Binlik ayırıcı ekle (.)
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatted = text.replaceAllMapped(reg, (Match m) => '${m[1]}.');

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
