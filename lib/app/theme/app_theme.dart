import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// [seedColor] opsional: default AppColors.primary (Ungu), tapi bisa
  /// diganti dinamis lewat SettingsProvider.accentColor (menu "Tema
  /// Warna" di Pengaturan) — lihat wiring di app.dart.
  static ThemeData light({Color seedColor = AppColors.primary}) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: AppColors.surface,
        ),
      );

  static ThemeData dark({Color seedColor = AppColors.primary}) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.textPrimaryDark,
          elevation: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: AppColors.surfaceDark,
        ),
      );
}
