import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_constants.dart';
import '../../core/providers/db_providers.dart';
import '../../core/database/models/transaction_record.dart';

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
  final groupingState = ref.watch(transactionGroupingProvider);

  return dbRecords.map((r) {
    final tx = MockTransaction.fromDB(r);
    // Gruplama durumunu uygula
    final groupId = groupingState[tx.id];
    if (groupId != null) {
      tx.groupId = groupId;
    }
    return tx;
  }).toList();
});

/// Hangi işlem hangi gruptadır? (in-memory gruplama durumu)
/// Key: transaction id (ör: "db_5"), Value: group id (ör: "g1234567")
final transactionGroupingProvider =
    StateNotifierProvider<TransactionGroupingNotifier, Map<String, String?>>(
      (ref) => TransactionGroupingNotifier(),
    );

class TransactionGroupingNotifier extends StateNotifier<Map<String, String?>> {
  TransactionGroupingNotifier() : super({});

  void setGroupId(String transactionId, String? groupId) {
    state = {...state, transactionId: groupId};
  }

  void removeTransaction(String transactionId) {
    state = Map.from(state)..remove(transactionId);
  }
}

/// Gruplar — StateNotifierProvider
final transactionGroupsProvider =
    StateNotifierProvider<TransactionGroupsNotifier, List<TransactionGroup>>(
      (ref) => TransactionGroupsNotifier(),
    );

class TransactionGroupsNotifier extends StateNotifier<List<TransactionGroup>> {
  TransactionGroupsNotifier() : super([]);

  int _nextGroupNum = 1;

  /// İki işlemi birleştirerek yeni grup oluştur
  String createGroup(String txId1, String txId2) {
    final groupId = 'g${DateTime.now().millisecondsSinceEpoch}';
    final group = TransactionGroup(
      id: groupId,
      name: 'Grup $_nextGroupNum',
      transactionIds: [txId1, txId2],
    );
    _nextGroupNum++;
    state = [...state, group];
    return groupId;
  }

  /// Grubun adını değiştir
  void renameGroup(String groupId, String newName) {
    state = [
      for (final g in state)
        if (g.id == groupId)
          TransactionGroup(
            id: g.id,
            name: newName,
            transactionIds: g.transactionIds,
          )
        else
          g,
    ];
  }

  /// Gruba işlem ekle
  void addToGroup(String groupId, String transactionId) {
    state = [
      for (final g in state)
        if (g.id == groupId)
          TransactionGroup(
            id: g.id,
            name: g.name,
            transactionIds: [...g.transactionIds, transactionId],
          )
        else
          g,
    ];
  }

  /// Gruptan işlem çıkar, grup boşalırsa sil
  void removeFromGroup(String groupId, String transactionId) {
    state = [
      for (final g in state)
        if (g.id == groupId)
          TransactionGroup(
            id: g.id,
            name: g.name,
            transactionIds: g.transactionIds
                .where((id) => id != transactionId)
                .toList(),
          )
        else
          g,
    ];
    // Grup 1 veya 0 elemanlı kaldıysa sil
    state = state.where((g) => g.transactionIds.length >= 2).toList();
  }

  /// Grubu tamamen sil
  void deleteGroup(String groupId) {
    state = state.where((g) => g.id != groupId).toList();
  }
}
