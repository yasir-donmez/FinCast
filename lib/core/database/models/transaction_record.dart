import 'package:isar/isar.dart';

part 'transaction_record.g.dart'; // Isar code generator tarafından üretilecek

@collection
class TransactionRecord {
  Id id = Isar.autoIncrement;

  /// İşlem Tipi: true -> Gelir, false -> Gider
  late bool isIncome;

  /// Kategori/Başlık (Hazır Modellerden Alınacak: Örn: "Market", "Netflix", "Kira")
  late String title;

  /// Kategori İkon Kodu (Arayüzde Neumorphic kartta gösterilmek üzere)
  String? iconCode;

  /// İşlemin tutarı. Eğer bir aralık (Range) seçildiyse bu değer ortalama (Veya maks) alınabilir
  /// Şimdilik net bir değer olarak tutuyoruz
  late double amount;

  /// --- Esnek Bütçeleme (Min-Max Aralık) ---
  /// Kullanıcı esnek bütçe (Range) belirlediyse buraya yazılır
  double? minAmount;
  double? maxAmount;

  /// "Kırmızı Çizgi / Kilit Mekanizması" (Zorunlu Gider mi?)
  /// Eğer true ise algoritma (Yapay Zeka) tasarruf tavsiyesi verirken bu kaleme asla dokunmaz!
  bool isLocked = false;

  /// "Taksit/Süreli Borç Mekanizması" 
  /// Eğer null değilse, bu giderin kalan ay sayısıdır. Her ay bu rakam düşer.
  int? remainingInstallments;

  /// Tekrarlama Periyodu (0: Tek Seferlik, 1: Haftalık, 2: Aylık, 3: Yıllık)
  int periodType = 0;

  /// Kaydın oluştuğu veya gerçekleşeceği tarih
  late DateTime date;

  /// Hangi Kasa (Vault) ile ilişkili? (İlişkisel Veritabanı kullanımı)
  /// Bu, ID üzerinden ilişki tutar
  late int vaultId;
}
