import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';

/// Jenis notifikasi — dipakai untuk ikon, warna, dan pengelompokan filter
/// di NotificationScreen (chip "Semua/Tugas/Jadwal/Pengingat/Sistem" pada
/// Figma). Sama seperti [TaskCategory], field ini tidak selalu ada di
/// dokumen Firestore lama, jadi selalu ada fallback penurunan dari kata
/// kunci judul lewat [inferNotificationType] di bawah.
enum NotificationType {
  deadlineTugas,
  tugasSelesai,
  tugasTerlambat,
  jadwal,
  pengingat,
  pengumuman,
  sistem,
}

extension NotificationTypeX on NotificationType {
  String get label => switch (this) {
        NotificationType.deadlineTugas => 'Deadline Tugas',
        NotificationType.tugasSelesai => 'Tugas Selesai',
        NotificationType.tugasTerlambat => 'Tugas Terlambat',
        NotificationType.jadwal => 'Jadwal',
        NotificationType.pengingat => 'Pengingat',
        NotificationType.pengumuman => 'Pengumuman',
        NotificationType.sistem => 'Sistem',
      };

  IconData get icon => switch (this) {
        NotificationType.deadlineTugas => Icons.menu_book_rounded,
        NotificationType.tugasSelesai => Icons.check_circle_rounded,
        NotificationType.tugasTerlambat => Icons.description_rounded,
        NotificationType.jadwal => Icons.science_rounded,
        NotificationType.pengingat => Icons.notifications_active_rounded,
        NotificationType.pengumuman => Icons.campaign_rounded,
        NotificationType.sistem => Icons.settings_suggest_rounded,
      };

  Color get color => switch (this) {
        NotificationType.deadlineTugas => AppColors.primary,
        NotificationType.tugasSelesai => AppColors.success,
        NotificationType.tugasTerlambat => AppColors.danger,
        NotificationType.jadwal => AppColors.warning,
        NotificationType.pengingat => AppColors.info,
        NotificationType.pengumuman => AppColors.secondary,
        NotificationType.sistem => AppColors.textSecondary,
      };

  /// Grup filter tempat jenis ini muncul, mengikuti chip di Figma
  /// (Tugas/Jadwal/Pengingat/Sistem).
  NotificationFilter get filterGroup => switch (this) {
        NotificationType.deadlineTugas ||
        NotificationType.tugasSelesai ||
        NotificationType.tugasTerlambat =>
          NotificationFilter.tugas,
        NotificationType.jadwal => NotificationFilter.jadwal,
        NotificationType.pengingat => NotificationFilter.pengingat,
        NotificationType.pengumuman || NotificationType.sistem =>
          NotificationFilter.sistem,
      };
}

/// Filter chip di atas daftar notifikasi. `semua` selalu cocok dengan
/// jenis apa pun; filter lain dicocokkan lewat [NotificationTypeX.filterGroup].
enum NotificationFilter { semua, tugas, jadwal, pengingat, sistem }

extension NotificationFilterX on NotificationFilter {
  String get label => switch (this) {
        NotificationFilter.semua => 'Semua',
        NotificationFilter.tugas => 'Tugas',
        NotificationFilter.jadwal => 'Jadwal',
        NotificationFilter.pengingat => 'Pengingat',
        NotificationFilter.sistem => 'Sistem',
      };

  bool matches(NotificationType type) {
    if (this == NotificationFilter.semua) return true;
    return type.filterGroup == this;
  }
}

/// Aturan penurunan jenis notifikasi dari judul & isi (dicek dari yang
/// paling spesifik), dipakai [NotificationModel.fromMap] sebagai fallback
/// kalau dokumen Firestore belum punya field `type` eksplisit, dan
/// dipanggil langsung di sana supaya field [NotificationModel.type] sudah
/// final & siap pakai tanpa perlu getter turunan lagi di layar UI:
/// 1. Kata kunci "terlambat" -> [NotificationType.tugasTerlambat]
/// 2. Kata kunci "selesai" -> [NotificationType.tugasSelesai]
/// 3. Kata kunci deadline/tugas -> [NotificationType.deadlineTugas]
/// 4. Kata kunci jadwal/praktikum/kuliah -> [NotificationType.jadwal]
/// 5. Kata kunci pengingat/ingat -> [NotificationType.pengingat]
/// 6. Kata kunci pengumuman/dosen -> [NotificationType.pengumuman]
/// 7. Selain itu -> [NotificationType.sistem] (default)
NotificationType inferNotificationType(String title, String body) {
  final text = '$title $body'.toLowerCase();

  if (text.contains('terlambat')) return NotificationType.tugasTerlambat;
  if (text.contains('selesai')) return NotificationType.tugasSelesai;

  const deadlineKeywords = ['deadline', 'tugas', 'jatuh tempo'];
  if (deadlineKeywords.any(text.contains)) return NotificationType.deadlineTugas;

  const scheduleKeywords = ['jadwal', 'praktikum', 'kuliah'];
  if (scheduleKeywords.any(text.contains)) return NotificationType.jadwal;

  const reminderKeywords = ['pengingat', 'ingat', 'jangan lupa'];
  if (reminderKeywords.any(text.contains)) return NotificationType.pengingat;

  const announcementKeywords = ['pengumuman', 'dosen', 'mengunggah'];
  if (announcementKeywords.any(text.contains)) return NotificationType.pengumuman;

  return NotificationType.sistem;
}

/// Nama enum (mis. "tugasSelesai") <-> [NotificationType], dipakai untuk
/// serialisasi field `type` ke/dari Firestore.
extension NotificationTypeParse on NotificationType {
  String get storageKey => name;

  static NotificationType? tryParse(String? raw) {
    if (raw == null) return null;
    for (final value in NotificationType.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}
