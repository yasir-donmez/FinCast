/// Para birimi ve tutar formatlama yardımları
class CurrencyUtils {
  /// Büyük tutarları K ve M şeklinde kısaltır (örn: 12.5K, 1.2M)
  static String formatAmount(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}K';
    } else {
      // 1000 altındaki değerler için kuruşsuz (tamsayı) gösterim yeterli
      return val.toStringAsFixed(0);
    }
  }

  /// Ondalık bakiye gösterimi (Dashboard ana bakiye için)
  /// Binlik ayırıcı ekler (örn: 131.692,50)
  static String formatFullAmount(double val) {
    if (val >= 1000000) {
      return formatAmount(
        val,
      ); // Milyonluk bakiyelerde kuruş göstermeye gerek yok
    }

    // Tamsayı ve ondalık kısımları ayır
    String parts = val.toStringAsFixed(2);
    if (parts.endsWith('.00')) {
      parts = parts.substring(0, parts.length - 3);
    }

    // Binlik ayırıcı ekle (Regex ile)
    // Önce noktayı (ondalık) geçici olarak koru, tamsayı kısmına ayırıcı ekle
    List<String> split = parts.split('.');
    String integerPart = split[0];
    String decimalPart = split.length > 1 ? split[1] : '';

    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    integerPart = integerPart.replaceAllMapped(reg, (Match m) => '${m[1]}.');

    if (decimalPart.isEmpty) return integerPart;
    return '$integerPart,$decimalPart';
  }
}
