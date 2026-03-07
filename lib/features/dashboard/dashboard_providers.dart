import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/db_providers.dart';

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
  });
}

/// Dashboard'da gösterilecek tüm öğeleri (Kasa/Grup + Tekil İşlem) birleştiren Provider
final dashboardItemsProvider = Provider<List<DashboardItem>>((ref) {
  final vaults = ref.watch(allVaultsProvider);
  final transactions = ref.watch(allTransactionsProvider);

  final List<DashboardItem> items = [];

  // 1. Görünür Kasaları (Grupları) ekle
  for (final v in vaults) {
    if (v.showOnDashboard) {
      // Kasa içindeki işlemleri bul
      final groupTx = transactions.where((t) => t.vaultId == v.id).toList();

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
          // Gider için: En iyi senaryo en az harcanmasıdır (max bakiye), En kötü senaryo en çok harcanmasıdır (min bakiye)
          groupMin -= t.maxAmount ?? t.amount;
          groupMax -= t.minAmount ?? t.amount;
        }
      }

      if (hasFlexibleTx && groupBalance == 0) {
        groupBalance = (groupMin + groupMax) / 2;
      }

      items.add(
        DashboardItem(
          id: 'v_${v.id}',
          name: v.name,
          balance: groupBalance,
          currency: v.currency,
          iconCode: v.iconCode,
          isGroup: true,
          itemIconCodes: groupTx
              .map((t) => t.iconCode ?? '')
              .where((c) => c.isNotEmpty)
              .take(50)
              .toList(),
          itemAmounts: groupTx
              .map((t) {
                if (t.amount == 0 &&
                    (t.minAmount != null || t.maxAmount != null)) {
                  return ((t.minAmount ?? 0) + (t.maxAmount ?? 0)) /
                      ((t.minAmount != null && t.maxAmount != null) ? 2 : 1);
                }
                return t.amount;
              })
              .take(50)
              .toList(),
          itemCount: groupTx.length,
          minLimit: hasFlexibleTx ? groupMin : v.minLimit,
          maxLimit: hasFlexibleTx ? groupMax : v.maxLimit,
        ),
      );
    }
  }

  // 2. Görünür Tekil İşlemleri ekle
  for (final t in transactions) {
    if (t.vaultId == null && t.showOnDashboard) {
      double effectiveAmount = t.amount;
      if (effectiveAmount == 0 &&
          (t.minAmount != null || t.maxAmount != null)) {
        effectiveAmount =
            ((t.minAmount ?? 0) + (t.maxAmount ?? 0)) /
            ((t.minAmount != null && t.maxAmount != null) ? 2 : 1);
      }

      items.add(
        DashboardItem(
          id: 't_${t.id}',
          name: t.title,
          balance: effectiveAmount,
          currency: '₺', // Şimdilik TL varsayalım
          iconCode: t.iconCode,
          isGroup: false,
          minLimit: t.minAmount,
          maxLimit: t.maxAmount,
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
