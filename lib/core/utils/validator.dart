/// Kumpulan validator form, dipusatkan supaya regex email/password tidak
/// diduplikasi di login/register/forgot-password/edit-profile screen.
/// Semua method mengembalikan `String?` sesuai kontrak `FormField.validator`.
class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');

  // Wajib huruf besar, huruf kecil, dan angka — minimal 6 karakter.
  static final RegExp _strongPasswordRegex =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{6,}$');

  static String? required(String? value, {String field = 'Bidang ini'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field tidak boleh kosong';
    }
    return null;
  }

  static String? minLength(String? value, int min, {String field = 'Bidang ini'}) {
    if (value == null || value.trim().length < min) {
      return '$field minimal $min karakter';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Validasi login: cuma cek panjang minimal, tidak perlu strong-password
  /// (itu aturan buat akun baru, bukan buat masuk ke akun lama).
  static String? loginPassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Kata sandi minimal 6 karakter';
    }
    return null;
  }

  /// Validasi register: wajib kombinasi huruf besar, huruf kecil, dan angka.
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi tidak boleh kosong';
    }
    if (!_strongPasswordRegex.hasMatch(value)) {
      return 'Minimal 6 karakter, kombinasi huruf besar/kecil & angka';
    }
    return null;
  }

  static String? name(String? value, {int minLength = 3}) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.trim().length < minLength) {
      return 'Nama terlalu pendek';
    }
    return null;
  }
}
