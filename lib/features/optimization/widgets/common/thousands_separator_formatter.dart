import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    
    // Sadece rakamları al
    String chars = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (chars.isEmpty) return const TextEditingValue();

    final n = int.tryParse(chars);
    if (n == null) return oldValue;

    final formatter = NumberFormat.decimalPattern('tr_TR');
    final newText = formatter.format(n);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
