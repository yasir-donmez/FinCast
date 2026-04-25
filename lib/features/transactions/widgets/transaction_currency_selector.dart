import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_constants.dart';

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
    return SizedBox(
      height: 64, // Peek için artırıldı
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Estetik Vurgu Çizgileri (Sabit ve Kompakt Genişlik)
          Container(
            width: 120, // Kasa seçici ile birebir aynı boyda olması için sabitlendi
            height: 34,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.getPrimary(context).withValues(alpha: 0.1), width: 0.8),
                bottom: BorderSide(color: AppColors.getPrimary(context).withValues(alpha: 0.1), width: 0.8),
              ),
            ),
          ),
          
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 32,
            physics: const FixedExtentScrollPhysics(),
            perspective: 0.006,
            diameterRatio: 1.0,
            overAndUnderCenterOpacity: 0.6, // Artırıldı
            useMagnifier: true,
            magnification: 1.2,
            onSelectedItemChanged: (index) {
              HapticFeedback.selectionClick();
              widget.onChanged(_options[index]);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _options.length,
              builder: (context, index) {
                final symbol = _options[index];
                final isSelected = widget.selectedCurrency == symbol;
                
                return Center(
                  child: Text(
                    symbol,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                      color: isSelected 
                          ? AppColors.getPrimary(context) 
                          : AppColors.getTextSecondary(context).withValues(alpha: 0.8),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
