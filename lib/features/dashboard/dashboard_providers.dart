import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/db_providers.dart';

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
