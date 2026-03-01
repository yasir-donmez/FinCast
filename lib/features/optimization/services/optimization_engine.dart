import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/models/transaction_record.dart';
import 'dart:math';

/// Kullanıcının hedefine ulaşması için "Kırmızı Çizgiler (Kilitler)" hariç
/// esnek giderleri ne oranda kısması gerektiğini hesaplayan Yapay Zeka Karar Motoru.
class OptimizationEngine {
  /// Verilen hedefe ulaşmak için esnek harcamalarda yapılması gereken kesinti oranlarını döndürür
  /// Dönen Map: { 'KategoriAdı': OnerilenAylikLimit }
  Map<String, double> calculateOptimalLimits({
    required double currentBalance,
    required double targetBalance,
    required int targetMonths,
    required List<TransactionRecord> recurringIncomes,
    required List<TransactionRecord>
    recurringExpenses, // İçinde hem kilitli hem kilitliler var
  }) {
    // 1. Ulaşılması gereken toplam boşluk (Aylık bazda ne kadar tasarruf lazım?)
    double requiredTotalGrowth = targetBalance - currentBalance;
    if (requiredTotalGrowth <= 0) {
      return {}; // Zaten hedefe ulaşılmış veya geçilmiş
    }

    double requiredMonthlySavings = requiredTotalGrowth / targetMonths;

    // 2. Mevcut Gelir/Gider Durumu
    double totalMonthlyIncome = _calculateTotal(recurringIncomes);

    // Kilitli (Dokunulamaz) ve Esnek (Kısılabilir) giderleri ayır.
    var lockedExpenses = recurringExpenses.where((e) => e.isLocked).toList();
    var flexibleExpenses = recurringExpenses.where((e) => !e.isLocked).toList();

    double lockedMonthlyTotal = _calculateTotal(lockedExpenses);
    double flexibleMonthlyTotal = _calculateTotal(flexibleExpenses);

    // Kalan harcanabilir para (Gelir - Zorunlu Giderler)
    double disposableIncome = totalMonthlyIncome - lockedMonthlyTotal;

    // Eğer zorunlu giderler bile gelirden fazlaysa, hedefe ulaşmak matematiksel olarak imkansız
    if (disposableIncome <= 0 || disposableIncome < requiredMonthlySavings) {
      // AI Koçu burada bir 'WARNING' fırlatmalı (Örn: Ek gelir yarat veya kilitleri iptal et)
      // Şimdilik kısıtlı optimizasyon olarak esnek harcamaların HEPSİNİ SIFIRA çekiyoruz.
      return {for (var e in flexibleExpenses) e.title: 0.0};
    }

    // Sistem esnek giderleri kısmalı.
    // Toplam bütçe ne kadar olmalı? -> Harcanabilir para eksi Hedeflenen aylık tasarruf
    double targetFlexibleBudget = disposableIncome - requiredMonthlySavings;

    // Eğer mevcut esnek harcamalar zaten hedeflenen bütçeden AZ ise, bir şeyi kısmaya gerek yok
    if (flexibleMonthlyTotal <= targetFlexibleBudget) {
      return {for (var e in flexibleExpenses) e.title: e.amount};
    }

    // 3. OPTİMİZASYON (Lineer Orantılı Kesinti)
    // Esnek harcamaları, mevcut ağırlıklarına göre kırpıyoruz. (Çok harcanan yerden çok kesilir)
    Map<String, double> optimizedLimits = {};

    for (var expense in flexibleExpenses) {
      // Bu kategorinin esnek giderler içindeki ağırlığı (Örn: %40'ı Eğlence)
      double weight = expense.amount / flexibleMonthlyTotal;

      // Yeni bütçeden bu kategoriye düşen (kırpılmış) pay
      double newLimit = targetFlexibleBudget * weight;

      // Kullanıcının "Minimum(Esnek Alt Limit)" kuralı varsa, algoritma o sınırın altına inemez
      double finalLimit = max(newLimit, expense.minAmount ?? 0);

      optimizedLimits[expense.title] = double.parse(
        finalLimit.toStringAsFixed(2),
      );
    }

    // NOT: Min kısıtlamalarından dolayı "targetFlexibleBudget" aşılmış olabilir,
    // o ikinci döngüde (ileri algoritma) çözülebilir. Şimdilik v1.0 startup kurgusu.
    return optimizedLimits;
  }

  double _calculateTotal(List<TransactionRecord> records) {
    return records.fold(0.0, (sum, record) {
      // İşlem türüne göre aylık değer bul (0: Tek, 1: Haftalık 2: Aylık 3: Yıllık)
      double monthlyAmount = record.amount;
      if (record.periodType == 1) monthlyAmount *= 4; // Haftalık
      if (record.periodType == 3) monthlyAmount /= 12; // Yıllık
      return sum + monthlyAmount;
    });
  }
}

// Global olarak erişilebilir Karar Motoru
final optimizationEngineProvider = Provider((ref) => OptimizationEngine());
