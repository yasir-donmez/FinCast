import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_constants.dart';

class AppTheme {
  /// Uygulamanın Tek ve Ana Teması: Premium Glassmorphism
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,

      // Arkaplan transparan ayarlıyoruz ki Scaffold içinde kendimiz Gradient verebilelim
      scaffoldBackgroundColor: Colors.transparent,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),

      // Tipografi: Fütüristik, premium ve okunaklı 'Inter' fontu
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.inter(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -1.5,
            ),
            displayMedium: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            bodyLarge: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: AppColors.textPrimary,
            ),
            bodyMedium: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: AppColors.textSecondary,
            ),
            labelLarge: GoogleFonts.inter(
              // Buton Yazıları
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 1.2,
            ),
          ),

      // Standart İkon Teması
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),
    );
  }
}
