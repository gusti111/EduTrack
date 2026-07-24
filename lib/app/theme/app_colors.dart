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
}
