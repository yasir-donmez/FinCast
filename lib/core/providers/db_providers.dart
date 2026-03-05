import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_service.dart';
import '../database/models/transaction_record.dart';
import '../database/models/vault.dart';

/// === İŞLEM PROVİDER'LARI ===

/// Tüm işlemleri canlı dinleyen stream provider
final transactionsStreamProvider = StreamProvider<List<TransactionRecord>>((
  ref,
) {
  return DatabaseService.watchAllTransactions();
});

/// Tüm işlemlerin anlık listesi (kolayca erişim için)
final allTransactionsProvider = Provider<List<TransactionRecord>>((ref) {
  return ref.watch(transactionsStreamProvider).valueOrNull ?? [];
});

/// Gelir işlemleri
final incomeTransactionsProvider = Provider<List<TransactionRecord>>((ref) {
  return ref.watch(allTransactionsProvider).where((t) => t.isIncome).toList();
});

/// Gider işlemleri
final expenseTransactionsProvider = Provider<List<TransactionRecord>>((ref) {
  return ref.watch(allTransactionsProvider).where((t) => !t.isIncome).toList();
});

/// Toplam gelir
final totalIncomeProvider = Provider<double>((ref) {
  return ref
      .watch(incomeTransactionsProvider)
      .fold<double>(0, (sum, t) => sum + t.amount);
});

/// Toplam gider
final totalExpenseProvider = Provider<double>((ref) {
  return ref
      .watch(expenseTransactionsProvider)
      .fold<double>(0, (sum, t) => sum + t.amount);
});

/// Net bakiye (gelir - gider)
final netBalanceProvider = Provider<double>((ref) {
  return ref.watch(totalIncomeProvider) - ref.watch(totalExpenseProvider);
});

/// === KASA PROVİDER'LARI ===

/// Kasaları canlı dinleyen stream provider
final vaultsStreamProvider = StreamProvider<List<Vault>>((ref) {
  return DatabaseService.watchAllVaults();
});

/// Kasaların anlık listesi
final allVaultsProvider = Provider<List<Vault>>((ref) {
  return ref.watch(vaultsStreamProvider).valueOrNull ?? [];
});
