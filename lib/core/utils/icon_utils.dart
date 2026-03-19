import 'package:flutter/material.dart';
import '../theme/app_constants.dart';

/// Tüm kategoriler ve alt modeller için ikon ve renk eşleşmelerini tutan merkezi yardımcı sınıf.
/// Bu sayede hem işlem eklerken hem de dashboard/kasalar sayfalarında tutarlı ikonlar gösterilir.
class IconUtils {
  /// Kategori ismi veya ikon koduna göre IconData döndürür.
  static IconData getIcon(String? code) {
    if (code == null || code.isEmpty) return Icons.receipt_rounded;

    final lowerCode = code.toLowerCase();
    
    // categoryId tabanlı eşleşme (ID'ler prefix içerir örn: exp_, inc_)
    switch (lowerCode) {
      // --- GİDER (EXPENSE) ---
      case 'exp_grocery':
      case 'exp_grocery_food':
        return Icons.egg_rounded;
      case 'exp_grocery_cleaning':
        return Icons.cleaning_services_rounded;
      case 'exp_grocery_personal':
        return Icons.face_rounded;
      
      case 'exp_dining':
        return Icons.restaurant_rounded;
      case 'exp_dining_restaurant':
        return Icons.restaurant_menu_rounded;
      case 'exp_dining_fastfood':
        return Icons.fastfood_rounded;
      case 'exp_dining_cafe':
        return Icons.coffee_rounded;
      case 'exp_dining_delivery':
        return Icons.delivery_dining_rounded;

      case 'exp_rent':
        return Icons.home_rounded;
      case 'exp_rent_home':
        return Icons.apartment_rounded;
      case 'exp_rent_office':
        return Icons.business_rounded;
      case 'exp_rent_storage':
        return Icons.warehouse_rounded;

      case 'exp_bill':
        return Icons.receipt_long_rounded;
      case 'exp_bill_electricity':
        return Icons.bolt_rounded;
      case 'exp_bill_water':
        return Icons.water_drop_rounded;
      case 'exp_bill_gas':
        return Icons.local_fire_department_rounded;
      case 'exp_bill_internet':
        return Icons.wifi_rounded;
      case 'exp_bill_phone':
        return Icons.phone_android_rounded;

      case 'exp_trans':
        return Icons.directions_car_rounded;
      case 'exp_trans_taxi':
        return Icons.local_taxi_rounded;
      case 'exp_trans_bus':
        return Icons.directions_bus_rounded;
      case 'exp_trans_train':
        return Icons.train_rounded;
      case 'exp_trans_flight':
        return Icons.flight_rounded;
      case 'exp_trans_fuel':
        return Icons.local_gas_station_rounded;

      case 'exp_fun':
        return Icons.movie_creation_rounded;
      case 'exp_fun_cinema':
        return Icons.local_movies_rounded;
      case 'exp_fun_concert':
        return Icons.music_note_rounded;
      case 'exp_fun_game':
        return Icons.sports_esports_rounded;
      case 'exp_fun_event':
        return Icons.event_rounded;

      case 'exp_sub':
        return Icons.subscriptions_rounded;
      case 'exp_sub_stream':
        return Icons.smart_display_rounded;
      case 'exp_sub_music':
        return Icons.headphones_rounded;
      case 'exp_sub_software':
        return Icons.code_rounded;
      case 'exp_sub_gym':
        return Icons.fitness_center_rounded;

      case 'exp_health':
        return Icons.medical_services_rounded;
      case 'exp_health_doctor':
        return Icons.local_hospital_rounded;
      case 'exp_health_medicine':
        return Icons.medication_rounded;
      case 'exp_health_surgery':
        return Icons.vaccines_rounded;
      case 'exp_health_dentist':
        return Icons.sentiment_satisfied_alt_rounded;

      case 'exp_cloth':
        return Icons.checkroom_rounded;
      case 'exp_cloth_daily':
        return Icons.dry_cleaning_rounded;
      case 'exp_cloth_shoes':
        return Icons.ice_skating_rounded;
      case 'exp_cloth_acc':
        return Icons.watch_rounded;

      case 'exp_edu':
        return Icons.school_rounded;
      case 'exp_edu_course':
        return Icons.menu_book_rounded;
      case 'exp_edu_book':
        return Icons.auto_stories_rounded;
      case 'exp_edu_school':
        return Icons.account_balance_rounded;

      case 'exp_debt':
      case 'exp_debt_credit_card':
        return Icons.credit_score_rounded;
      case 'exp_debt_loan':
        return Icons.account_balance_rounded;
      case 'exp_debt_personal':
        return Icons.handshake_rounded;

      // --- GELİR (INCOME) ---
      case 'inc_salary':
        return Icons.account_balance_wallet_rounded;
      case 'inc_salary_main':
        return Icons.payments_rounded;
      case 'inc_salary_bonus':
        return Icons.card_giftcard_rounded;
      case 'inc_salary_dividend':
        return Icons.celebration_rounded;

      case 'inc_extra':
        return Icons.monetization_on_rounded;
      case 'inc_extra_freelance':
        return Icons.laptop_mac_rounded;
      case 'inc_extra_parttime':
        return Icons.work_outline_rounded;
      case 'inc_extra_commission':
        return Icons.handshake_rounded;

      case 'inc_invest':
        return Icons.trending_up_rounded;
      case 'inc_invest_stock':
        return Icons.show_chart_rounded;
      case 'inc_invest_crypto':
        return Icons.currency_bitcoin_rounded;
      case 'inc_invest_interest':
        return Icons.savings_rounded;

      case 'inc_scholarship':
        return Icons.school_rounded;
      case 'inc_scholarship_award':
        return Icons.emoji_events_rounded;
      case 'inc_scholarship_loan':
        return Icons.account_balance_rounded;

      case 'inc_sale':
        return Icons.store_rounded;
      case 'inc_sale_online':
        return Icons.shopping_cart_rounded;
      case 'inc_sale_physical':
        return Icons.storefront_rounded;

      case 'inc_rent':
        return Icons.house_rounded;
      case 'inc_rent_home':
        return Icons.apartment_rounded;
      case 'inc_rent_office':
        return Icons.business_rounded;

      case 'inc_gift':
        return Icons.card_giftcard_rounded;
    }

    // Ana Kategoriler ve Alt Modeller Karışık Eşleşme (Geriye Dönük Uyumluluk için String-Based)
    switch (lowerCode) {
      // Market
      case 'market':
        return Icons.shopping_basket_rounded;
      case 'gıda':
        return Icons.egg_rounded;
      case 'temizlik':
        return Icons.cleaning_services_rounded;
      case 'kişisel bakım':
        return Icons.face_rounded;

      // Yemek
      case 'yemek':
        return Icons.restaurant_rounded;
      case 'restoran':
        return Icons.restaurant_menu_rounded;
      case 'fast food':
        return Icons.fastfood_rounded;
      case 'kafe':
        return Icons.coffee_rounded;
      case 'paket servis':
        return Icons.delivery_dining_rounded;

      // Kira
      case 'kira':
        return Icons.home_rounded;
      case 'ev kirası':
        return Icons.apartment_rounded;
      case 'iş yeri':
        return Icons.business_rounded;
      case 'depo':
        return Icons.warehouse_rounded;

      // Fatura
      case 'fatura':
        return Icons.receipt_long_rounded;
      case 'elektrik':
        return Icons.bolt_rounded;
      case 'su':
        return Icons.water_drop_rounded;
      case 'doğalgaz':
        return Icons.local_fire_department_rounded;
      case 'internet':
        return Icons.wifi_rounded;
      case 'telefon':
        return Icons.phone_android_rounded;

      // Ulaşım
      case 'ulaşım':
        return Icons.directions_car_rounded;
      case 'taksi':
        return Icons.local_taxi_rounded;
      case 'otobüs':
        return Icons.directions_bus_rounded;
      case 'tren':
        return Icons.train_rounded;
      case 'uçak':
        return Icons.flight_rounded;
      case 'yakıt':
        return Icons.local_gas_station_rounded;

      // Eğlence
      case 'eğlence':
        return Icons.movie_creation_rounded;
      case 'sinema':
        return Icons.local_movies_rounded;
      case 'konser':
        return Icons.music_note_rounded;
      case 'oyun':
        return Icons.sports_esports_rounded;
      case 'etkinlik':
        return Icons.event_rounded;

      // Abonelik
      case 'abonelik':
        return Icons.subscriptions_rounded;
      case 'dizi/film':
        return Icons.smart_display_rounded;
      case 'müzik':
        return Icons.headphones_rounded;
      case 'yazılım':
        return Icons.code_rounded;
      case 'spor salonu':
        return Icons.fitness_center_rounded;

      // Sağlık
      case 'sağlık':
        return Icons.medical_services_rounded;
      case 'doktor':
        return Icons.local_hospital_rounded;
      case 'ilaç':
        return Icons.medication_rounded;
      case 'ameliyat':
        return Icons.vaccines_rounded;
      case 'diş':
        return Icons.sentiment_satisfied_alt_rounded;

      // Giyim
      case 'giyim':
        return Icons.checkroom_rounded;
      case 'günlük':
        return Icons.dry_cleaning_rounded;
      case 'ayakkabı':
        return Icons.ice_skating_rounded;
      case 'aksesuar':
        return Icons.watch_rounded;

      // Eğitim
      case 'eğitim':
        return Icons.school_rounded;
      case 'kurs':
        return Icons.menu_book_rounded;
      case 'kitap':
        return Icons.auto_stories_rounded;
      case 'okul':
        return Icons.account_balance_rounded;

      // Borç
      case 'borç ödeme':
        return Icons.credit_card_rounded;
      case 'kredi kartı':
        return Icons.credit_score_rounded;
      case 'bireysel kredi':
        return Icons.account_balance_rounded;
      case 'kişisel borç':
        return Icons.handshake_rounded;

      // --- GELİR ---
      case 'maaş':
        return Icons.account_balance_wallet_rounded;
      case 'ana maaş':
        return Icons.payments_rounded;
      case 'prim':
        return Icons.card_giftcard_rounded;
      case 'ikramiye':
        return Icons.celebration_rounded;

      case 'ek gelir':
        return Icons.monetization_on_rounded;
      case 'freelance':
        return Icons.laptop_mac_rounded;
      case 'part-time':
        return Icons.work_outline_rounded;
      case 'komisyon':
        return Icons.handshake_rounded;

      case 'yatırım getirisi':
        return Icons.trending_up_rounded;
      case 'hisse':
        return Icons.show_chart_rounded;
      case 'kripto':
        return Icons.currency_bitcoin_rounded;
      case 'faiz':
        return Icons.savings_rounded;

      case 'burs / kredi':
      case 'burs':
        return Icons.emoji_events_rounded;

      case 'satış':
        return Icons.store_rounded;
      case 'online satış':
        return Icons.shopping_cart_rounded;
      case 'fiziksel satış':
        return Icons.storefront_rounded;

      case 'kira geliri':
        return Icons.house_rounded;
      case 'ev':
        return Icons.apartment_rounded;

      case 'hediye':
        return Icons.card_giftcard_rounded;

      // Özel Kasa İkonları
      case 'account_balance_wallet_rounded':
        return Icons.account_balance_wallet_rounded;
      case 'attach_money_rounded':
        return Icons.attach_money_rounded;
      case 'diamond_rounded':
        return Icons.diamond_rounded;

      case 'diğer':
      default:
        return Icons.receipt_rounded;
    }
  }

  /// Kategori ismi veya ikon koduna göre Renk döndürür.
  static Color getColor(String? code) {
    if (code == null || code.isEmpty) return AppColors.darkTextSecondary;

    final lowerCode = code.toLowerCase();

    // categoryId tabanlı renk eşleşmesi
    if (lowerCode.startsWith('exp_grocery')) return Colors.orange;
    if (lowerCode.startsWith('exp_dining')) return Colors.deepOrangeAccent;
    if (lowerCode.startsWith('exp_rent')) return Colors.blue;
    if (lowerCode.startsWith('exp_bill')) return Colors.lightBlue;
    if (lowerCode.startsWith('exp_trans')) return Colors.teal;
    if (lowerCode.startsWith('exp_fun')) return AppColors.secondary;
    if (lowerCode.startsWith('exp_sub')) return AppColors.error;
    if (lowerCode.startsWith('exp_health')) return Colors.greenAccent;
    if (lowerCode.startsWith('exp_cloth')) return Colors.pinkAccent;
    if (lowerCode.startsWith('exp_edu')) return Colors.amber;
    if (lowerCode.startsWith('exp_debt')) return Colors.redAccent;
    
    if (lowerCode.startsWith('inc_salary')) return AppColors.primary;
    if (lowerCode.startsWith('inc_extra')) return Colors.green;
    if (lowerCode.startsWith('inc_invest')) return Colors.blueAccent;
    if (lowerCode.startsWith('inc_scholarship')) return Colors.amber;
    if (lowerCode.startsWith('inc_sale')) return Colors.orangeAccent;
    if (lowerCode.startsWith('inc_rent')) return AppColors.secondary;
    if (lowerCode.startsWith('inc_gift')) return Colors.pinkAccent;

    // Market
    if (['market', 'gıda', 'temizlik', 'kişisel bakım'].contains(lowerCode)) {
      return Colors.orange;
    }
    // Yemek
    if ([
      'yemek',
      'restoran',
      'fast food',
      'kafe',
      'paket servis',
    ].contains(lowerCode)) {
      return Colors.deepOrangeAccent;
    }
    // Kira / Fatura
    if ([
      'kira',
      'ev kirası',
      'iş yeri',
      'depo',
      'fatura',
      'elektrik',
      'su',
      'doğalgaz',
      'internet',
      'telefon',
    ].contains(lowerCode)) {
      return Colors.blue;
    }
    // Ulaşım
    if ([
      'ulaşım',
      'taksi',
      'otobüs',
      'tren',
      'uçak',
      'yakıt',
    ].contains(lowerCode)) {
      return Colors.teal;
    }
    // Eğlence
    if ([
      'eğlence',
      'sinema',
      'konser',
      'oyun',
      'etkinlik',
    ].contains(lowerCode)) {
      return AppColors.secondary;
    }
    // Abonelik / Borç
    if ([
      'abonelik',
      'dizi/film',
      'müzik',
      'yazılım',
      'spor salonu',
      'borç ödeme',
      'kredi kartı',
      'bireysel kredi',
      'kişisel borç',
    ].contains(lowerCode)) {
      return AppColors.error;
    }
    // Sağlık
    if (['sağlık', 'doktor', 'ilaç', 'ameliyat', 'diş'].contains(lowerCode)) {
      return Colors.greenAccent;
    }
    // Giyim
    if (['giyim', 'günlük', 'ayakkabı', 'aksesuar'].contains(lowerCode)) {
      return Colors.pinkAccent;
    }
    // Eğitim
    if (['eğitim', 'kurs', 'kitap', 'okul'].contains(lowerCode)) {
      return Colors.amber;
    }
    // Maaş
    if (['maaş', 'ana maaş', 'prim', 'ikramiye'].contains(lowerCode)) {
      return AppColors.primary;
    }
    // Ek Gelir / Satış
    if ([
      'ek gelir',
      'freelance',
      'part-time',
      'komisyon',
      'satış',
      'online satış',
      'fiziksel satış',
    ].contains(lowerCode)) {
      return Colors.green;
    }
    // Yatırım
    if (['yatırım getirisi', 'hisse', 'kripto', 'faiz'].contains(lowerCode)) {
      return Colors.blueAccent;
    }

    // Filtrelemede kullanılan özel durumlar (Dolar/Altın)
    if (lowerCode.contains('dolar')) {
      return Colors.greenAccent;
    }
    if (lowerCode.contains('yastık') || lowerCode.contains('altın')) {
      return Colors.amberAccent;
    }

    return AppColors.darkTextSecondary;
  }

  /// Bir listedeki en çok tekrar eden ikon kodunu döndürür.
  static String? getDominantIconCode(List<String?> iconCodes) {
    if (iconCodes.isEmpty) return null;
    final Map<String, int> counts = {};
    for (final code in iconCodes) {
      if (code == null || code.isEmpty) continue;
      counts[code] = (counts[code] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}
