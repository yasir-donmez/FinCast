import 'package:isar/isar.dart';

part 'transaction_record.g.dart'; // Isar code generator tarafından üretilecek

@collection
class TransactionRecord {
  Id id = Isar.autoIncrement;

  /// İşlem Tipi: true -> Gelir, false -> Gider
  bool isIncome = false;

  String title = '';
  
  /// Kategori ID (Multi-language desteği için benzersiz anahtar)
  String? categoryId;

  /// Kategori İkon Kodu (Arayüzde Neumorphic kartta gösterilmek üzere)
  String? iconCode;

  /// İşlemin tutarı. Eğer bir aralık (Range) seçildiyse bu değer ortalama (Veya maks) alınabilir
  /// Şimdilik net bir değer olarak tutuyoruz
  double amount = 0.0;

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

  /// Tekrarlama Periyodu (0: Tek Seferlik, 1: Haftalık, 2: Aylık, 3: Yıllık, 4: 2 Haftada Bir, 5: 3 Haftada Bir, 6: 3 Ayda Bir, 7: 6 Ayda Bir, 8: Günlük, 9: 2 Günde Bir, 10: 3 Günde Bir)
  int periodType = 0;

  /// Tekrarlama Detayları (Haftanın Hangi Günü, Ayın Hangi Günü vb.)
  int? recurrenceDay;
  DateTime? recurrenceDate;

  /// Kaç kez tekrar edeceği (0 = Sonsuz/Sürekli Tekrar Eder)
  int? recurrenceDuration;

  /// Kaydın oluştuğu veya gerçekleşeceği tarih
  DateTime date = DateTime.now();

  /// Hangi Kasalar (Vault) ile ilişkili? (Çoklu Kasa Desteği)
  /// İşlem tektir ancak birden fazla kasada listelenebilir.
  List<int> vaultIds = [];

  /// Ana sayfada gösterilsin mi?
  bool showOnDashboard = false;

  /// Dashboard'daki sıralama
  int dashboardOrder = 0;

  /// Dashboard'da bu işlemin dahil olduğu sayfanın yerleşim tipi (1, 2, 3, 4)
  int dashboardLayoutType = 4;

  /// Arşiv bayrağı: Süresi dolmuş periyodik işlemler silinmez, arşivlenir.
  /// true → aktif listede görünmez, analiz motoru geçmiş hesabında kullanır.
  bool isArchived = false;

  /// İşleme dair not veya açıklama
  String? note;

  /// İşlemin yapıldığı para birimi (USD, TRY vb.)
  String? currency;

  /// İşlemin yapıldığı konumun koordinatları
  double? latitude;
  double? longitude;

  /// --- Senkronizasyon Alanları ---
  /// Sunucu anahtarı (UUID)
  @Index()
  String? remoteId;

  /// Son güncelleme tarihi (Eşitleme için)
  @Index()
  DateTime updatedAt = DateTime.now();

  /// Senkronizasyon Durumu (0: Senkronize, 1: Beklemede, 2: Silindi)
  @Index()
  int syncStatus = 0;

  /// İşlemin aylık karşılığını hesaplar.
  /// Dashboard ve Analiz motoru arasındaki tutarsızlığı önlemek için bu metod kullanılmalıdır.
  @ignore
  double get monthlyEquivalent {
    switch (periodType) {
      case 1: // Haftalık
        return amount * (52 / 12);
      case 2: // Aylık
        return amount;
      case 3: // Yıllık
        return amount / 12;
      case 4: // 2 Haftada Bir
        return amount * (26 / 12);
      case 5: // 3 Haftada Bir (Yılda yaklaşık 17.33 kez = 52/3)
        return amount * (52 / 3 / 12);
      case 6: // 3 Ayda Bir
        return amount / 3;
      case 7: // 6 Ayda Bir
        return amount / 6;
      case 8: // Günlük
        return amount * (365 / 12);
      case 9: // 2 Günde Bir
        return amount * (365 / 2 / 12);
      case 10: // 3 Günde Bir
        return amount * (365 / 3 / 12);
      default: // Tek seferlik
        return 0;
    }
  }
}
