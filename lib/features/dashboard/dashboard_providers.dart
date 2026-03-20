import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/db_providers.dart';
import '../../core/utils/icon_utils.dart';
import '../vaults/vaults_providers.dart';

/// Dashboard'da gösterilecek ortak kart veri modeli
class DashboardItem {
  final String id;
  final String name;
  final double balance;
  final String currency;
  final String? iconCode;
  final bool isGroup;
  final List<String> itemIconCodes;
  final List<double> itemAmounts;
  final int itemCount;
  final double? minLimit;
  final double? maxLimit;
  final int dashboardOrder;
  final int dashboardLayoutType;

  DashboardItem({
    required this.id,
    required this.name,
    required this.balance,
    required this.currency,
    this.iconCode,
    this.isGroup = false,
    this.itemIconCodes = const [],
    this.itemAmounts = const [],
    this.itemCount = 0,
    this.minLimit,
    this.maxLimit,
    this.dashboardOrder = 0,
    this.dashboardLayoutType = 4,
  });
}

/// Dashboard'da gösterilecek tüm öğeleri (Kasa/Grup + Tekil İşlem) birleştiren Provider
final dashboardItemsProvider = Provider<List<DashboardItem>>((ref) {
  final vaults = ref.watch(allVaultsProvider);
  final transactions = ref.watch(mockTransactionsProvider);

  final List<DashboardItem> items = [];

  // 1. Görünür Kasaları (Grupları) ekle
  final sortedVaults = vaults.where((v) => v.showOnDashboard).toList()
    ..sort((a, b) {
      int cmp = a.dashboardOrder.compareTo(b.dashboardOrder);
      if (cmp == 0) return a.id.compareTo(b.id);
      return cmp;
    });

  for (final v in sortedVaults) {
    // Kasa içindeki işlemleri bul
    final groupTx = transactions.where((t) => t.groupId == 'v_${v.id}').toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    double groupBalance = 0;
    double groupMin = 0;
    double groupMax = 0;
    bool hasFlexibleTx = false;

    for (final t in groupTx) {
      if (t.isIncome) {
        groupBalance += t.amount;
        if (t.minAmount != null || t.maxAmount != null) hasFlexibleTx = true;
        groupMin += t.minAmount ?? t.amount;
        groupMax += t.maxAmount ?? t.amount;
      } else {
        groupBalance -= t.amount;
        if (t.minAmount != null || t.maxAmount != null) hasFlexibleTx = true;
        groupMin -= t.maxAmount ?? t.amount;
        groupMax -= t.minAmount ?? t.amount;
      }
    }

    if (hasFlexibleTx && groupBalance == 0) {
      groupBalance = (groupMin + groupMax) / 2;
    }

    // En çok tekrar eden ismi bul (Dominant Icon için isim kullanılıyor)
    final dominantIconCode =
        IconUtils.getDominantIconCode(groupTx.map((t) => t.name).toList()) ??
        v.iconCode;

    items.add(
      DashboardItem(
        id: 'v_${v.id}',
        name: v.name,
        balance: groupBalance,
        currency: v.currency,
        iconCode: dominantIconCode,
        isGroup: true,
        itemIconCodes: groupTx
            .map((t) => t.name)
            .where((c) => c.isNotEmpty)
            .take(50)
            .toList(),
        itemAmounts: groupTx
            .map((t) => t.isIncome ? t.amount : -t.amount)
            .take(50)
            .toList(),
        itemCount: groupTx.length,
        minLimit: hasFlexibleTx ? groupMin : v.minLimit,
        maxLimit: hasFlexibleTx ? groupMax : v.maxLimit,
        dashboardOrder: v.dashboardOrder,
        dashboardLayoutType: v.dashboardLayoutType,
      ),
    );
  }

  // 2. Görünür Tekil İşlemleri ekle
  for (final t in transactions) {
    if (t.groupId == null && t.showOnDashboard) {
      // mockTransaction follows the UI model
      items.add(
        DashboardItem(
          id: 't_${t.dbId}',
          name: t.name,
          balance: t.isIncome ? t.amount : -t.amount,
          currency: '₺',
          iconCode: t.name, // or icon mapping
          isGroup: false,
          minLimit: t.minAmount,
          maxLimit: t.maxAmount,
          dashboardOrder: 0, // Default for standalone
          dashboardLayoutType: t.dashboardLayoutType,
        ),
      );
    }
  }

  return items;
});

/// Zaman makinesi tekerleği çevrildiğinde eklenen sanal (gelecek) bakiye bonusu
final simulationBonusProvider = StateProvider<double>((ref) => 0.0);

/// Ekranda gösterilecek toplam bakiye: Gerçek Bakiye (DB) + Zaman Makinesi Bonusu
final displayBalanceProvider = Provider<double>((ref) {
  final realBalance = ref.watch(netBalanceProvider);
  final bonus = ref.watch(simulationBonusProvider);
  return realBalance + bonus;
});

/// Renklerin zaman içinde iPhone vari bir spektrumla (Gökkuşağı/Progressive) değişmesini sağlayan Provider
final rotaryColorProvider = StateProvider<Color>(
  (ref) => const Color(0xFF00E5FF),
);

/// Zaman makinesinin şu an hangi "Ay/Yıl" ofsetinde olduğunu tutar (0 = Bugün)
final timeOffsetProvider = StateProvider<int>((ref) => 0);
