import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/db_providers.dart';
import '../../core/database/database_service.dart';
import '../../core/database/models/transaction_record.dart';
import '../../core/database/models/vault.dart';
import '../../core/utils/icon_utils.dart';

/// Tek bir işlem kaydı (UI Model)
class TransactionUI {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double amount;
  final double? minAmount;
  final double? maxAmount;
  final bool isIncome;
  final int periodType; // 0: Tek Seferlik, 1: Haftalık, 2: Aylık, 3: Yıllık
  final DateTime date;
  final int? remainingInstallments; // Taksit sayısı (varsa)
  final int? dbId; // Isar DB ID (null = henüz kaydedilmemiş)
  final String? categoryId; // Multi-language desteği için benzersiz anahtar
  final String? iconCode;   // İkon referansı (ID veya özel kod)
  final bool showOnDashboard;
  final int dashboardLayoutType;
  String? groupId; // null ise grupsuz

  TransactionUI({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
    this.minAmount,
    this.maxAmount,
    required this.isIncome,
    required this.periodType,
    required this.date,
    this.remainingInstallments,
    this.dbId,
    this.categoryId,
    this.iconCode,
    required this.showOnDashboard,
    this.dashboardLayoutType = 4,
    this.groupId,
  });

  /// Belirli bir tutarın aylık karşılığını hesaplar.
  double _calculateMonthly(double baseAmount) {
    switch (periodType) {
      case 1: // Haftalık
        return baseAmount * (52 / 12);
      case 2: // Aylık
        return baseAmount;
      case 3: // Yıllık
        return baseAmount / 12;
      case 4: // 2 Haftada Bir
        return baseAmount * (26 / 12);
      case 5: // 3 Haftada Bir
        return baseAmount * (52 / 3 / 12);
      case 6: // 3 Ayda Bir
        return baseAmount / 3;
      case 7: // 6 Ayda Bir
        return baseAmount / 6;
      case 8: // Günlük
        return baseAmount * (365 / 12);
      case 9: // 2 Günde Bir
        return baseAmount * (365 / 2 / 12);
      case 10: // 3 Günde Bir
        return baseAmount * (365 / 3 / 12);
      default: // Tek seferlik
        return 0;
    }
  }

  /// İşlemin aylık karşılığını hesaplar.
  double get monthlyEquivalent => _calculateMonthly(amount);

  /// Minimum aylık karşılık (esnek işlemler için)
  double get minMonthlyEquivalent => _calculateMonthly(minAmount ?? amount);

  /// Maksimum aylık karşılık (esnek işlemler için)
  double get maxMonthlyEquivalent => _calculateMonthly(maxAmount ?? amount);

  /// Ortalama aylık karşılık (esnek işlemler için)
  double get avgMonthlyEquivalent {
    if (minAmount != null && maxAmount != null) {
      return _calculateMonthly((minAmount! + maxAmount!) / 2);
    }
    return monthlyEquivalent;
  }

  /// TransactionRecord'dan TransactionUI'a dönüştür
  factory TransactionUI.fromDB(TransactionRecord record) {
    return TransactionUI(
      id: 'db_${record.id}',
      name: record.title,
      icon: IconUtils.getIcon(record.iconCode ?? record.title),
      color: IconUtils.getColor(record.iconCode ?? record.title),
      amount: record.amount,
      minAmount: record.minAmount,
      maxAmount: record.maxAmount,
      isIncome: record.isIncome,
      periodType: record.periodType,
      date: record.date,
      remainingInstallments: record.remainingInstallments,
      dbId: record.id,
      categoryId: record.categoryId,
      iconCode: record.iconCode,
      showOnDashboard: record.showOnDashboard,
      dashboardLayoutType: record.dashboardLayoutType,
    );
  }
}

/// İşlem grubu (Klasör mantığı)
class TransactionGroup {
  final String id;
  String name;
  final List<String> transactionIds;

  TransactionGroup({
    required this.id,
    required this.name,
    List<String>? transactionIds,
  }) : transactionIds = transactionIds ?? [];

  /// DB Vault modelinden TransactionGroup'a dönüştür
  factory TransactionGroup.fromDB(Vault vault, List<TransactionRecord> allTx) {
    final relatedTxIds = allTx.where((t) => t.vaultId == vault.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final txIds = relatedTxIds.map((t) => 'db_${t.id}').toList();

    return TransactionGroup(
      id: 'v_${vault.id}',
      name: vault.name,
      transactionIds: txIds,
    );
  }
}

/// Filtreleme tipi
enum TransactionFilter { all, income, expense }

/// Aktif filtre
final transactionFilterProvider = StateProvider<TransactionFilter>(
  (ref) => TransactionFilter.all,
);

/// DB'den gelen işlemleri UI modeline çeviren provider
final vaultTransactionsProvider = Provider<List<TransactionUI>>((ref) {
  final dbRecords = ref.watch(allTransactionsProvider);

  return dbRecords.map((r) {
    final tx = TransactionUI.fromDB(r);
    // Gruplama durumunu DB vaultId'den al
    if (r.vaultId != null) {
      tx.groupId = 'v_${r.vaultId}';
    }
    return tx;
  }).toList();
});

/// Gruplama işlemi için yardımcı notifier
/// Artık sadece DB operasyonlarını tetikler
final transactionGroupingProvider = Provider(
  (ref) => TransactionGroupingHelper(),
);

class TransactionGroupingHelper {
  Future<void> setGroupId(String transactionId, String? groupId) async {
    if (!transactionId.startsWith('db_')) return;
    final id = int.tryParse(transactionId.replaceFirst('db_', ''));
    if (id == null) return;

    final record = await DatabaseService.getTransaction(id);
    if (record == null) return;

    if (groupId == null) {
      record.vaultId = null;
    } else if (groupId.startsWith('v_')) {
      final vId = int.tryParse(groupId.replaceFirst('v_', ''));
      record.vaultId = vId;
    }

    await DatabaseService.updateTransaction(record);
  }
}

/// Gruplar — Database tabanlı provider
final transactionGroupsProvider = Provider<List<TransactionGroup>>((ref) {
  final vaults = ref.watch(allVaultsProvider);
  final allTx = ref.watch(vaultTransactionsProvider);

  return vaults.map((v) {
    final relatedTxIds = allTx.where((t) => t.groupId == 'v_${v.id}').toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return TransactionGroup(
      id: 'v_${v.id}',
      name: v.name,
      transactionIds: relatedTxIds.map((t) => t.id).toList(),
    );
  }).toList();
});

/// Grup işlemleri için yardımcı notifier
final transactionGroupsNotifierProvider = Provider(
  (ref) => TransactionGroupsHelper(),
);

class TransactionGroupsHelper {
  /// Grubun adını değiştir
  Future<void> renameGroup(String groupId, String newName) async {
    if (!groupId.startsWith('v_')) return;
    final id = int.tryParse(groupId.replaceFirst('v_', ''));
    if (id == null) return;

    final vaults = await DatabaseService.getAllVaults();
    final vault = vaults.where((v) => v.id == id).firstOrNull;
    if (vault != null) {
      vault.name = newName;
      await DatabaseService.updateVault(vault);
    }
  }

  /// Gruba işlem ekle
  Future<void> addToGroup(String groupId, String transactionId) async {
    final helper = TransactionGroupingHelper();
    await helper.setGroupId(transactionId, groupId);
  }

  /// Gruptan işlem çıkar
  Future<void> removeFromGroup(String groupId, String transactionId) async {
    final helper = TransactionGroupingHelper();
    await helper.setGroupId(transactionId, null);

    // Eğer grupta hiç işlem kalmadıysa (veya 1 tane kaldıysa kullanıcının tercihine göre) grubu silebiliriz.
    // Ancak şimdilik manuel silmeyi bekleyelim veya otomatik kontrol ekleyelim.
  }

  /// Grubu tamamen sil
  Future<void> deleteGroup(String groupId) async {
    if (!groupId.startsWith('v_')) return;
    final id = int.tryParse(groupId.replaceFirst('v_', ''));
    if (id == null) return;

    // Önce bu gruptaki tüm işlemleri çıkar
    final allTx = await DatabaseService.getAllTransactions();
    final relatedTx = allTx.where((t) => t.vaultId == id);
    for (final tx in relatedTx) {
      tx.vaultId = null;
      await DatabaseService.updateTransaction(tx);
    }

    // Kasayı (Grubu) sil
    await DatabaseService.deleteVault(id);
  }

  /// Kasaların sırasını güncelle (Sıralama özelliği için)
  Future<void> reorderGroups(List<String> groupIds) async {
    final vaults = await DatabaseService.getAllVaults();
    final updatedVaults = <Vault>[];

    for (int i = 0; i < groupIds.length; i++) {
      final groupId = groupIds[i];
      if (!groupId.startsWith('v_')) continue;
      final id = int.tryParse(groupId.replaceFirst('v_', ''));
      if (id == null) continue;

      final vault = vaults.where((v) => v.id == id).firstOrNull;
      if (vault != null) {
        vault.dashboardOrder = i;
        updatedVaults.add(vault);
      }
    }

    if (updatedVaults.isNotEmpty) {
      await DatabaseService.updateAllVaults(updatedVaults);
    }
  }
}

/// Seçili kasa (null = Ana Kasa / Tümü)
final selectedVaultProvider = StateProvider<String?>((ref) => null);

/// Seçili periyot (null = Tümü, 0: Tek Seferlik, 1: Haftalık, 2: Aylık, 3: Yıllık)
final selectedPeriodProvider = StateProvider<int?>((ref) => null);
