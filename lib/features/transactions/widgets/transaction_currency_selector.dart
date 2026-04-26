import 'package:flutter/material.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/precision_inline_picker.dart';

class TransactionCurrencySelector extends StatefulWidget {
  final String selectedCurrency;
  final ValueChanged<String> onChanged;

  const TransactionCurrencySelector({
    super.key,
    required this.selectedCurrency,
    required this.onChanged,
  });

  @override
  State<TransactionCurrencySelector> createState() => _TransactionCurrencySelectorState();
}

class _TransactionCurrencySelectorState extends State<TransactionCurrencySelector> {
  late FixedExtentScrollController _controller;
  final List<String> _options = AppCurrency.supportedSymbols;

  @override
  void initState() {
    super.initState();
    int index = _options.indexOf(widget.selectedCurrency);
    if (index == -1) index = 0;
    _controller = FixedExtentScrollController(initialItem: index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int currentIndex = _options.indexOf(widget.selectedCurrency);
    if (currentIndex == -1) currentIndex = 0;

    return PrecisionInlinePicker(
      items: _options,
      selectedIndex: currentIndex,
      onChanged: (index) {
        widget.onChanged(_options[index]);
      },
      width: 120,
    );
  }
}
