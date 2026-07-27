import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import 'task_model.dart';

/// Kategori tugas untuk keperluan grafik donat di StatisticsScreen
/// ("Tugas Berdasarkan Kategori" pada Figma).
///
/// Tidak ada field `category` tersendiri di Firestore — menambah field baru
/// berarti migrasi data & form Tambah Tugas yang lebih rumit lagi. Sebagai
/// gantinya, kategori diturunkan (derived) dari `subject` dan kata kunci di
/// `title` yang sudah ada, mirip pola `TaskModel.effectiveStatus`.
enum TaskCategory { tugas, praktikum, kuisUjian, proyek }

extension TaskCategoryX on TaskCategory {
  String get label => switch (this) {
        TaskCategory.tugas => 'Tugas',
        TaskCategory.praktikum => 'Praktikum',
        TaskCategory.kuisUjian => 'Quiz / Ujian',
        TaskCategory.proyek => 'Proyek',
      };

  Color get color => switch (this) {
        TaskCategory.tugas => AppColors.primary,
        TaskCategory.praktikum => AppColors.success,
        TaskCategory.kuisUjian => AppColors.warning,
        TaskCategory.proyek => AppColors.info,
      };
}

extension TaskCategoryOf on TaskModel {
  /// Aturan pencocokan (urutan penting — dicek dari yang paling spesifik):
  /// 1. Mata kuliah "Praktikum" -> [TaskCategory.praktikum]
  /// 2. Judul mengandung kata kunci ujian/kuis -> [TaskCategory.kuisUjian]
  /// 3. Judul mengandung kata kunci proyek -> [TaskCategory.proyek]
  /// 4. Selain itu -> [TaskCategory.tugas] (default)
  TaskCategory get category {
    final text = '$title $subject'.toLowerCase();

    if (subject == 'Praktikum') return TaskCategory.praktikum;

    const examKeywords = ['ujian', 'uts', 'uas', 'kuis', 'quiz', 'exam'];
    if (examKeywords.any(text.contains)) return TaskCategory.kuisUjian;

    const projectKeywords = ['proyek', 'project'];
    if (projectKeywords.any(text.contains)) return TaskCategory.proyek;

    return TaskCategory.tugas;
  }
}
