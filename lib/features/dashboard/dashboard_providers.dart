import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/models/vault.dart';

/// Kullanıcının o anki net serveti (Zaman makinesi slider'i hareket ettikçe burası değişecek)
final totalBalanceProvider = StateProvider<double>((ref) => 125000.50);

/// Renklerin zaman içinde iPhone vari bir spektrumla (Gökkuşağı/Progressive) değişmesini sağlayan Provider
final rotaryColorProvider = StateProvider<Color>(
  (ref) => const Color(0xFF00E5FF),
);

/// Zaman makinesinin şu an hangi "Ay/Yıl" ofsetinde olduğunu tutar (0 = Bugün)
final timeOffsetProvider = StateProvider<int>((ref) => 0);

/// Geçici (Mock) Kasa (Vault) Listesi - Isar DB bağlanana kadar UI tasarımı için kullanılır
final mockVaultsProvider = Provider<List<Vault>>((ref) {
  return [
    Vault()
      ..id = 1
      ..name = "Maaş Hesabı"
      ..currency = "TRY"
      ..balance = 45000.0
      ..iconCode = "account_balance_wallet_rounded",

    Vault()
      ..id = 2
      ..name = "Dolar Zulası"
      ..currency = "USD"
      ..balance = 1200.0
      ..iconCode = "attach_money_rounded",

    Vault()
      ..id = 3
      ..name = "Yastık Altı"
      ..currency =
          "GRAM" // Gram Altın Temsili
      ..balance = 15.5
      ..iconCode = "diamond_rounded",
  ];
});
