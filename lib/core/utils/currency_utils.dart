import '../database/models/exchange_rate.dart';

/// Para birimi ve tutar formatlama yardımları
class CurrencyUtils {
  /// Tutar formatlama (Kısa gösterim)
  static String formatAmount(double val) {
    if (val.abs() >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M';
    }
    return formatFullAmount(val, includeDecimals: false);
  }

  /// Ondalık bakiye gösterimi (Dashboard ve Detaylar için)
  static String formatFullAmount(double val, {bool includeDecimals = true}) {
    if (val.abs() >= 10000000) {
      return '${(val / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M';
    }

    String parts = (val.abs()).toStringAsFixed(includeDecimals ? 2 : 0);
    List<String> split = parts.split('.');
    String integerPart = split[0];
    String decimalPart = split.length > 1 ? split[1] : '';

    if (decimalPart == '00') decimalPart = '';

    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    integerPart = integerPart.replaceAllMapped(reg, (Match m) => '${m[1]}.');

    String result = integerPart;
    if (decimalPart.isNotEmpty) result = '$integerPart,$decimalPart';
    
    return val < 0 ? '-$result' : result;
  }

  /// Tutarı kurlara göre baz birime (TRY) veya başka bir birime çevirir
  static double convert(double amount, String from, String to, List<ExchangeRate> rates) {
    if (from == to) return amount;
    
    // 1. Tutar'ı TRY'ye (Baz birim) getir
    double tryAmount = amount;
    if (from != 'TRY' && from != '₺' && from != 'AUTO') {
      final fromCode = _normalizeCode(from);
      final fromRate = rates.where((r) => r.currencyCode == fromCode).firstOrNull;
      if (fromRate != null) {
        tryAmount = amount * fromRate.rate;
      }
    }
    
    // 2. TRY tutarını hedef birime çevir
    if (to == 'TRY' || to == '₺' || to == 'AUTO') return tryAmount;
    
    final toCode = _normalizeCode(to);
    final toRate = rates.where((r) => r.currencyCode == toCode).firstOrNull;
    if (toRate != null) {
      return tryAmount / toRate.rate;
    }
    
    return tryAmount;
  }

  /// Sembolleri API kodlarıyla eşleştirir ($, € -> USD, EUR)
  static String _normalizeCode(String symbol) {
    if (symbol == '\$') return 'USD';
    if (symbol == '€') return 'EUR';
    if (symbol == 'G') return 'GOLD';
    if (symbol == 'ALTIN') return 'GOLD';
    return symbol;
  }
}
