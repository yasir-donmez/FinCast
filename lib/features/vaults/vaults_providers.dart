import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_constants.dart';
import '../../core/providers/db_providers.dart';
import '../../core/database/database_service.dart';
import '../../core/database/models/transaction_record.dart';
import '../../core/database/models/vault.dart';

/// Tek bir işlem kaydı (UI Model)
class MockTransaction {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double amount;
  final double? minAmount;
  final double? maxAmount;
  final bool isIncome;
  final int? dbId; // Isar DB ID (null = henüz kaydedilmemiş)
  String? groupId; // null ise grupsuz

  MockTransaction({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
    this.minAmount,
    this.maxAmount,
    required this.isIncome,
    this.dbId,
    this.groupId,
  });

  /// TransactionRecord'dan MockTransaction'a dönüştür
  factory MockTransaction.fromDB(TransactionRecord record) {
    final mapping =
        _categoryMapping[record.title] ??
        _categoryMapping[record.iconCode] ??
        {'icon': Icons.receipt_rounded, 'color': AppColors.textSecondary};

    return MockTransaction(
      id: 'db_${record.id}',
      name: record.title,
      icon: mapping['icon'] as IconData,
      color: mapping['color'] as Color,
      amount: record.amount,
      minAmount: record.minAmount,
      maxAmount: record.maxAmount,
      isIncome: record.isIncome,
      dbId: record.id,
    );
  }

  /// Kategori ismi → ikon & renk eşleştirmesi
  static final Map<String, Map<String, dynamic>> _categoryMapping = {
    'Market': {'icon': Icons.shopping_basket_rounded, 'color': Colors.orange},
    'Yemek': {
      'icon': Icons.restaurant_rounded,
      'color': Colors.deepOrangeAccent,
    },
    'Kira': {'icon': Icons.home_rounded, 'color': Colors.blue},
    'Fatura': {'icon': Icons.receipt_long_rounded, 'color': Colors.lightBlue},
    'Elektrik': {'icon': Icons.bolt_rounded, 'color': Colors.amber},
    'Su': {'icon': Icons.water_drop_rounded, 'color': Colors.cyan},
    'İnternet': {'icon': Icons.wifi_rounded, 'color': Colors.lightBlue},
    'Telefon': {'icon': Icons.phone_android_rounded, 'color': Colors.lightBlue},
    'Ulaşım': {'icon': Icons.directions_car_rounded, 'color': Colors.teal},
    'Taksi': {'icon': Icons.local_taxi_rounded, 'color': Colors.teal},
    'Otobüs': {'icon': Icons.directions_bus_rounded, 'color': Colors.teal},
    'Eğlence': {
      'icon': Icons.movie_creation_rounded,
      'color': AppColors.secondary,
    },
    'Abonelik': {'icon': Icons.subscriptions_rounded, 'color': AppColors.error},
    'Netflix': {'icon': Icons.smart_display_rounded, 'color': AppColors.error},
    'Spotify': {'icon': Icons.headphones_rounded, 'color': Colors.green},
    'Sağlık': {
      'icon': Icons.medical_services_rounded,
      'color': Colors.greenAccent,
    },
    'Giyim': {'icon': Icons.checkroom_rounded, 'color': Colors.pink},
    'Eğitim': {'icon': Icons.school_rounded, 'color': Colors.indigo},
    'Borç Ödeme': {
      'icon': Icons.credit_card_rounded,
      'color': Colors.redAccent,
    },
    'Restoran': {
      'icon': Icons.restaurant_rounded,
      'color': Colors.deepOrangeAccent,
    },
    'Spor Salonu': {
      'icon': Icons.fitness_center_rounded,
      'color': Colors.pinkAccent,
    },
    'Maaş': {
      'icon': Icons.account_balance_wallet_rounded,
      'color': AppColors.primary,
    },
    'Freelance': {'icon': Icons.laptop_mac_rounded, 'color': Colors.green},
    'Kira Geliri': {
      'icon': Icons.real_estate_agent_rounded,
      'color': Colors.blue,
    },
    'Faiz': {'icon': Icons.savings_rounded, 'color': Colors.blueAccent},
    'Ek İş': {'icon': Icons.work_rounded, 'color': Colors.orange},
    'Burs': {'icon': Icons.school_rounded, 'color': Colors.indigo},
    'Diğer': {
      'icon': Icons.more_horiz_rounded,
      'color': AppColors.textSecondary,
    },
  };
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
    final relatedTxIds = allTx
        .where((t) => t.vaultId == vault.id)
        .map((t) => 'db_${t.id}')
        .toList();

    return TransactionGroup(
      id: 'v_${vault.id}',
      name: vault.name,
      transactionIds: relatedTxIds,
    );
  }
}

/// Filtreleme tipi
enum TransactionFilter { all, income, expense }

/// Aktif filtre
final transactionFilterProvider = StateProvider<TransactionFilter>(
  (ref) => TransactionFilter.all,
);

/// Edit modu açık mı?
final editModeProvider = StateProvider<bool>((ref) => false);

/// DB'den gelen işlemleri MockTransaction'a çeviren provider
final mockTransactionsProvider = Provider<List<MockTransaction>>((ref) {
  final dbRecords = ref.watch(allTransactionsProvider);

  return dbRecords.map((r) {
    final tx = MockTransaction.fromDB(r);
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
  final allTx = ref.watch(allTransactionsProvider);

  return vaults.map((v) => TransactionGroup.fromDB(v, allTx)).toList();
});

/// Grup işlemleri için yardımcı notifier
final transactionGroupsNotifierProvider = Provider(
  (ref) => TransactionGroupsHelper(),
);

class TransactionGroupsHelper {
  static int _nextGroupNum = 1;

  /// İki işlemi birleştirerek yeni grup (Vault) oluştur
  Future<String> createGroup(String txId1, String txId2) async {
    final name = 'Kasa ${_nextGroupNum++}';

    final vault = Vault()
      ..name = name
      ..currency =
          'TRY' // Varsayılan
      ..balance = 0
      ..showOnDashboard = true;

    final vaultId = await DatabaseService.addVault(vault);
    final groupId = 'v_$vaultId';

    // İşlemleri bu gruba ata
    final helper = TransactionGroupingHelper();
    await helper.setGroupId(txId1, groupId);
    await helper.setGroupId(txId2, groupId);

    return groupId;
  }

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

    // Kasayı (Grubu) sil (Not: DatabaseService.deleteVault henüz yok, eklememiz gerekebilir veya update yetebilir)
    // Şimdilik sadece içini boşaltıyoruz. Gerçek silme için DatabaseService'e metod ekleyelim.
  }
}
