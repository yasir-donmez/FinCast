import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/transaction_record.dart';
import 'models/vault.dart';

/// Isar Veritabanı Servisi — Singleton
class DatabaseService {
  static Isar? _isar;

  /// Isar veritabanı instance'ı
  static Isar get isar {
    if (_isar == null) throw Exception('DatabaseService.init() çağrılmamış!');
    return _isar!;
  }

  /// DB'yi başlat (main.dart'ta çağrılacak)
  static Future<void> init() async {
    if (_isar != null) return; // Zaten açık

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open([
      TransactionRecordSchema,
      VaultSchema,
    ], directory: dir.path);

    // İlk açılışta varsayılan kasaları ekle
    await _seedDefaultVaults();
  }

  /// İlk kullanımda varsayılan kasaları oluştur (Artık boş, kullanıcı grup oluşturunca eklenecek)
  static Future<void> _seedDefaultVaults() async {
    // mock verileri sildik
  }

  // =====================
  // TRANSACTION CRUD
  // =====================

  /// Yeni işlem ekle
  static Future<int> addTransaction(TransactionRecord tx) async {
    return await isar.writeTxn(() async {
      return await isar.transactionRecords.put(tx);
    });
  }

  /// İşlemi güncelle
  static Future<void> updateTransaction(TransactionRecord tx) async {
    await isar.writeTxn(() async {
      await isar.transactionRecords.put(tx);
    });
  }

  /// İşlemi sil
  static Future<void> deleteTransaction(int id) async {
    await isar.writeTxn(() async {
      await isar.transactionRecords.delete(id);
    });
  }

  /// Tek bir işlemi ID ile getir
  static Future<TransactionRecord?> getTransaction(int id) async {
    return await isar.transactionRecords.get(id);
  }

  /// Tüm işlemleri getir
  static Future<List<TransactionRecord>> getAllTransactions() async {
    return await isar.transactionRecords.where().findAll();
  }

  /// Gelir işlemlerini getir
  static Future<List<TransactionRecord>> getIncomeTransactions() async {
    return await isar.transactionRecords
        .filter()
        .isIncomeEqualTo(true)
        .findAll();
  }

  /// Gider işlemlerini getir
  static Future<List<TransactionRecord>> getExpenseTransactions() async {
    return await isar.transactionRecords
        .filter()
        .isIncomeEqualTo(false)
        .findAll();
  }

  /// İşlemleri canlı dinle (Stream)
  static Stream<List<TransactionRecord>> watchAllTransactions() {
    return isar.transactionRecords.where().watch(fireImmediately: true);
  }

  // =====================
  // VAULT CRUD
  // =====================

  /// Tüm kasaları getir
  static Future<List<Vault>> getAllVaults() async {
    return await isar.vaults.where().findAll();
  }

  /// Kasa ekle
  static Future<int> addVault(Vault vault) async {
    return await isar.writeTxn(() async {
      return await isar.vaults.put(vault);
    });
  }

  /// Kasa güncelle
  static Future<void> updateVault(Vault vault) async {
    await isar.writeTxn(() async {
      await isar.vaults.put(vault);
    });
  }

  /// Kasa sil
  static Future<void> deleteVault(int id) async {
    await isar.writeTxn(() async {
      await isar.vaults.delete(id);
    });
  }

  /// Kasaları canlı dinle
  static Stream<List<Vault>> watchAllVaults() {
    return isar.vaults.where().watch(fireImmediately: true);
  }
}
