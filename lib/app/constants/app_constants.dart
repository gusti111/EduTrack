/// Konstanta umum yang dipakai lintas layer (UI, validator, dsb).
/// Dipisah dari [FirestorePaths] karena isinya bukan soal struktur data,
/// tapi soal aturan/tampilan aplikasi.
class AppConstants {
  AppConstants._();

  static const String appName = 'EduTrack';
  static const String appTagline = 'Smart Student Planner';

  // Aturan form — dipakai bareng oleh Validator & screen auth.
  static const int minPasswordLength = 6;
  static const int minNameLength = 3;

  // Durasi umum animasi/snackbar, biar konsisten di semua screen.
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration debounceDuration = Duration(milliseconds: 400);
}
