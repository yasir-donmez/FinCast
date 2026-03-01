import 'package:flutter/material.dart';

class AppColors {
  // --- Realistic Dark Skeuomorphism (Neumorphism) Temel Renkleri ---

  /// Ana Zemin Rengi (Tam siyah değil, sıcak ve derin koyu gri / antrasit)
  static const Color background = Color(0xFF292C31);

  /// Kart / Element Rengi (Zemine çok yakın, hafif açık/koyu olabilir)
  static const Color surface = Color(0xFF2F3237);

  /// Işık Yansıması (Sol üstten vuran yumuşak beyaz/gri ışık)
  static const Color lightShadow = Color(0x1AFFFFFF); // %10 Beyaz

  /// Karanlık Gölge (Sağ alttan vuran derin siyah gölge)
  static const Color darkShadow = Color(0x80000000); // %50 Siyah

  /// İçeri Göçme (Deboss) arkaplanı (Zeminden bir tık daha karanlık)
  static const Color innerSurface = Color(0xFF22252A);

  // --- Vurgu (Accent) Renkleri (Görseldeki gibi parlak Cyan) ---

  /// Ana Vurgu Rengi (Parlak Neon Camgöbeği)
  static const Color primary = Color(0xFF00E5FF);

  /// İkincil Vurgu Rengi (Opsiyonel, mor ya da turkuaz)
  static const Color secondary = Color(0xFFB388FF);

  static const Color error = Color(0xFFFF5252);

  // --- Yazı (Text) Renkleri ---

  static const Color textPrimary = Color(0xFFE0E0E0); // Kırık beyaz

  static const Color textSecondary = Color(
    0xFF8A8F99,
  ); // Koyu gri okunaklı metin
}

class AppSizes {
  // Radüs ve Boşluk Sabitleri
  static const double radiusDefault = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusRound = 100.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
}
