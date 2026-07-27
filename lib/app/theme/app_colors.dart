import 'package:flutter/material.dart';

/// Palet warna EduTrack — single source of truth.
/// Jangan hardcode hex/Colors.xxx langsung di screen; pakai konstanta di sini
/// supaya kalau brand color berubah, cukup diganti satu tempat.
class AppColors {
  AppColors._();

  // --- Brand (purple/indigo) ---
  static const Color primary = Color(0xFF5B5FEF);
  static const Color primaryDark = Color(0xFF4347C4);
  static const Color primaryLight = Color(0xFFE3E4FC);
  static const Color secondary = Color(0xFF8B8FF7);

  // --- Semantic (dipakai konsisten dengan TaskPriority/TaskStatus) ---
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE08A2C);
  static const Color danger = Color(0xFFD7473F);
  static const Color info = Color(0xFF3A7BD5);

  // --- Neutral ---
  static const Color textPrimary = Color(0xFF1D1E2C);
  static const Color textSecondary = Color(0xFF6B6D80);
  static const Color divider = Color(0xFFE3E4EA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7F7FB);

  // --- Dark mode ---
  static const Color surfaceDark = Color(0xFF1C1C28);
  static const Color backgroundDark = Color(0xFF121218);
  static const Color textPrimaryDark = Color(0xFFEDEDF4);
  static const Color textSecondaryDark = Color(0xFFA0A2B8);
  static const Color dividerDark = Color(0xFF2E2E3C);
  static const Color primaryLightDark = Color(0xFF2C2D52);

  /// --- Helper context-aware (dark-mode-safe) ---
  /// Dipakai di seluruh screen alih-alih `AppColors.background` dsb
  /// langsung, supaya tampilan benar-benar berubah mengikuti Mode Gelap
  /// (bukan cuma warna aksen/tema warna) alih-alih tetap terang karena
  /// nilainya di-hardcode.
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) => _isDark(context) ? backgroundDark : background;

  static Color surfaceOf(BuildContext context) => _isDark(context) ? surfaceDark : surface;

  static Color textPrimaryOf(BuildContext context) => _isDark(context) ? textPrimaryDark : textPrimary;

  static Color textSecondaryOf(BuildContext context) => _isDark(context) ? textSecondaryDark : textSecondary;

  static Color dividerOf(BuildContext context) => _isDark(context) ? dividerDark : divider;

  static Color primaryLightOf(BuildContext context) => _isDark(context) ? primaryLightDark : primaryLight;
}
