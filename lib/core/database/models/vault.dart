import 'package:isar/isar.dart';

part 'vault.g.dart'; // Isar code generator tarafından üretilecek

@collection
class Vault {
  Id id = Isar.autoIncrement;

  /// Kasanın Adı (Örn: "Maaş Hesabı", "Yastık Altı Altın", "Dolar Zulası")
  late String name;

  /// Kasanın Ana Birimi (Örn: "TRY", "USD", "GRAM")
  late String currency;

  /// Kasadaki Toplam Miktar (Örn: 25000.0)
  late double balance;

  /// Kasaya özel İkon veya renk kodu (Arayüzde şık Neumorphic buton için)
  String? iconCode;

  /// Bu kasa "genel net servet (toplam bakiye)" hesaplamasına dahil edilsin mi?
  bool isIncludedInTotal = true;
}
