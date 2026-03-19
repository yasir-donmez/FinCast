import 'package:flutter/material.dart';
import 'app_constants.dart';

class AppTheme {
  static ThemeData? _darkTheme;
  static ThemeData? _lightTheme;

  static ThemeData get darkTheme {
    _darkTheme ??= _buildDarkTheme();
    return _darkTheme!;
  }

  static ThemeData get lightTheme {
    _lightTheme ??= _buildLightTheme();
    return _lightTheme!;
  }

  /// Premium Glassmorphism - Karanlık Tema
  static ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.error,
      ),
      textTheme: _buildTextTheme(
        Typography.material2021(platform: TargetPlatform.android).white,
        AppColors.darkTextPrimary,
        AppColors.darkTextSecondary,
      ),
      iconTheme: const IconThemeData(color: AppColors.darkTextSecondary, size: 24),
    );
  }

  /// Premium Glassmorphism - Aydınlık Tema
  static ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        error: AppColors.error,
      ),
      textTheme: _buildTextTheme(
        Typography.material2021(platform: TargetPlatform.android).black,
        AppColors.lightTextPrimary,
        AppColors.lightTextSecondary,
      ),
      iconTheme: const IconThemeData(color: AppColors.lightTextSecondary, size: 24),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Color primaryColor, Color secondaryColor) {
    TextStyle premiumTextStyle({
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
      double? letterSpacing,
    }) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }

    return base.copyWith(
      displayLarge: premiumTextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: primaryColor,
        letterSpacing: -1.5,
      ),
      displayMedium: premiumTextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        letterSpacing: -0.5,
      ),
      bodyLarge: premiumTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      bodyMedium: premiumTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
      ),
      labelLarge: premiumTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: 1.2,
      ),
    );
  }
}
