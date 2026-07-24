import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Style teks yang dipakai berulang di luar default [TextTheme] Material,
/// misal untuk judul splash/auth atau caption kecil di card.
/// Untuk teks biasa (headline/body/label standar), tetap pakai
/// `Theme.of(context).textTheme` — ini cuma pelengkap yang khas EduTrack.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle brandTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle sectionHeading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle statLabel = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );
}
