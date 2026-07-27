import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';

/// Daftar mata kuliah yang bisa dipilih di form Tambah/Edit Tugas.
/// Disimpan sebagai String biasa di Firestore (bukan enum) supaya fleksibel
/// kalau daftar mata kuliah tiap mahasiswa beda-beda — daftar di sini
/// cuma dipakai sebagai pilihan cepat di dropdown.
class TaskSubjects {
  TaskSubjects._();

  static const List<String> options = [
    'Matematika',
    'Fisika',
    'Bahasa Inggris',
    'Design UI/UX',
    'Database',
    'PBO',
    'Praktikum',
    'Lainnya',
  ];
}

/// Icon & warna per mata kuliah, dicocokkan dengan desain Figma (tiap mata
/// kuliah punya warna badge sendiri di TaskCard/HomeScreen). Mata kuliah
/// yang tidak dikenali (custom, hasil ketik manual) jatuh ke [_fallback].
class TaskSubjectVisual {
  const TaskSubjectVisual(this.icon, this.color);

  final IconData icon;
  final Color color;

  static const _fallback = TaskSubjectVisual(Icons.menu_book, AppColors.primary);

  static const Map<String, TaskSubjectVisual> _map = {
    'Matematika': TaskSubjectVisual(Icons.menu_book, AppColors.primary),
    'Fisika': TaskSubjectVisual(Icons.science_outlined, AppColors.success),
    'Bahasa Inggris': TaskSubjectVisual(Icons.chat_bubble_outline, Color(0xFF3A7BD5)),
    'Design UI/UX': TaskSubjectVisual(Icons.edit_outlined, AppColors.warning),
    'Database': TaskSubjectVisual(Icons.check_circle_outline, AppColors.success),
    'PBO': TaskSubjectVisual(Icons.description_outlined, AppColors.danger),
    'Praktikum': TaskSubjectVisual(Icons.science_outlined, AppColors.warning),
  };

  static TaskSubjectVisual of(String subject) => _map[subject] ?? _fallback;
}
