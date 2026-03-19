import '../database/database_service.dart';

/// Süresi dolan işlemleri arşivleme servisi
/// Uygulama açılışında çağrılır.
class DataRetentionService {
  /// dataRetentionDays ayarına göre eski işlemleri arşivle.
  /// Arşivlenen işlemler aktif listede görünmez ama analizde kullanılır.
  static Future<void> archiveExpiredTransactions() async {
    final settings = await DatabaseService.getSettings();
    final retentionDays = settings.dataRetentionDays;

    // -1 = sonsuz, hiçbir şey arşivleme
    if (retentionDays == -1) return;

    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    final allTx = await DatabaseService.getAllTransactions();

    final toArchive = allTx.where((tx) {
      if (tx.isArchived) return false; // Zaten arşivlenmiş

      // Tek seferlik işlem (periodType == 0): tarihine bak
      if (tx.periodType == 0) {
        return tx.date.isBefore(cutoff);
      }

      // Periyodik işlem: kalan taksit 0 olmuş ve tarih geçmiş
      if (tx.remainingInstallments != null && tx.remainingInstallments! <= 0) {
        return tx.date.isBefore(cutoff);
      }

      return false;
    }).toList();

    if (toArchive.isEmpty) return;

    for (final tx in toArchive) {
      tx.isArchived = true;
    }

    await DatabaseService.updateAllTransactions(toArchive);
  }
}
