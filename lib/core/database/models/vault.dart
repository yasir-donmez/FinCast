import 'package:isar/isar.dart';

part 'vault.g.dart'; // Isar code generator tarafından üretilecek

@collection
class Vault {
  Id id = Isar.autoIncrement;

  /// Kasanın Adı (Örn: "Maaş Hesabı", "Yastık Altı Altın", "Dolar Zulası")
  String name = '';

  /// Kasanın Ana Birimi (Örn: "TRY", "USD", "GRAM")
  String currency = 'TRY';

  /// Kasadaki Toplam Miktar (Örn: 25000.0)
  double balance = 0.0;

  /// Kasaya özel İkon veya renk kodu (Arayüzde şık Neumorphic buton için)
  String? iconCode;

  /// Bu kasa "genel net servet (toplam bakiye)" hesaplamasına dahil edilsin mi?
  bool isIncludedInTotal = true;

  /// Ana sayfada gösterilsin mi?
  bool showOnDashboard = true;

  /// Hedef/Limit değerleri (Opsiyonel)
  double? minLimit;
  double? maxLimit;

  /// Dashboard'daki sıralama
  int dashboardOrder = 0;

  /// Dashboard'da bu vault'un dahil olduğu sayfanın yerleşim tipi (1, 2, 3, 4)
  int dashboardLayoutType = 4;

  /// --- Senkronizasyon Alanları ---
  @Index()
  String? remoteId;

  @Index()
  DateTime updatedAt = DateTime.now();

  @Index()
  int syncStatus = 0;
}
