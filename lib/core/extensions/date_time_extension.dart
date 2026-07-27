import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  String get toDisplayDate => DateFormat('dd MMM yyyy').format(this);

  /// Jam dalam format 24 jam (mis. "09:00"), dipakai TaskCard, HomeScreen,
  /// dan AddEditTaskScreen supaya format waktu konsisten di seluruh app.
  String get toDisplayTime => DateFormat('HH:mm').format(this);

  /// Tanggal lengkap berbahasa Indonesia (mis. "Sabtu, 19 Jul 2025"),
  /// dipakai header Agenda di CalendarScreen. Locale 'id_ID' sudah
  /// diinisialisasi sekali di bootstrap.dart lewat initializeDateFormatting,
  /// jadi aman dipanggil kapan pun.
  String get toDisplayDateLong =>
      DateFormat('EEEE, d MMM yyyy', 'id_ID').format(this);

  bool get isPastNow => isBefore(DateTime.now());

  /// Tanggal awal minggu (Senin) yang memuat [this], jam di-reset ke 00:00.
  DateTime get startOfWeek {
    final normalized = DateTime(year, month, day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }
}
