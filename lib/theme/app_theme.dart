import 'package:flutter/material.dart';

/// Canonical UMART palette. New code should use [AppTheme.light] /
/// `Theme.of(context).colorScheme` instead of redefining hex values per file.
abstract final class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4C6B3F);
  static const Color primaryDark = Color(0xFF2C3E24);
  static const Color primaryLight = Color(0xFF799B61);
  static const Color accent = Color(0xFFF27B35);
  static const Color background = Color(0xFFF5F7F2);
  static const Color ink = Color(0xFF1A1A2E);
}

abstract final class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.ink, size: 20),
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.primary,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFEEEEEE)),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
