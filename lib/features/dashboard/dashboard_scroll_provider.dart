import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard'un scroll durumunu paylaşmak için provider.
final dashboardScrollProvider = Provider<ScrollController>((ref) {
  final controller = ScrollController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

/// Scroll yönünü takip eden provider (true = Yukarı/Duruyor, false = Aşağı).
final isScrollingDownProvider = StateProvider<bool>((ref) => false);
