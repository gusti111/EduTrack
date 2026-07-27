import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/theme/app_colors.dart';
import '../models/notification_type.dart';

/// Pilihan warna aksen tema — mengubah `seedColor` Material di seluruh
/// app (lihat AppTheme.light/dark & app.dart), sesuai menu "Tema Warna"
/// pada Figma.
enum AppAccentColor { ungu, biru, hijau, oranye, merahMuda }

extension AppAccentColorX on AppAccentColor {
  String get label => switch (this) {
        AppAccentColor.ungu => 'Ungu',
        AppAccentColor.biru => 'Biru',
        AppAccentColor.hijau => 'Hijau',
        AppAccentColor.oranye => 'Oranye',
        AppAccentColor.merahMuda => 'Merah Muda',
      };

  Color get color => switch (this) {
        AppAccentColor.ungu => AppColors.primary,
        AppAccentColor.biru => const Color(0xFF2F80ED),
        AppAccentColor.hijau => const Color(0xFF27AE60),
        AppAccentColor.oranye => const Color(0xFFF2994A),
        AppAccentColor.merahMuda => const Color(0xFFEB5B8C),
      };
}

/// 3 zona waktu Indonesia — dipakai TimezoneScreen & (nantinya) buat
/// menampilkan jam lokal user di luar WIB.
const List<String> kTimezoneOptions = [
  'Waktu Indonesia Barat (WIB)',
  'Waktu Indonesia Tengah (WITA)',
  'Waktu Indonesia Timur (WIT)',
];

/// Preset nada dering notifikasi (belum ada file audio sungguhan di
/// project ini — ini murni preferensi yang dipersist, siap disambungkan
/// ke package seperti `audioplayers` kalau assetnya sudah tersedia).
const List<String> kRingtoneOptions = [
  'Default',
  'Chime',
  'Bell',
  'Marimba',
  'Ping',
  'Tanpa Suara',
];

/// Kategori notifikasi yang bisa dimatikan/dinyalakan satu-satu di
/// NotificationSettingsScreen, sejajar dengan chip filter di
/// NotificationScreen (lihat [NotificationFilter]).
const List<NotificationFilter> kToggleableCategories = [
  NotificationFilter.tugas,
  NotificationFilter.jadwal,
  NotificationFilter.pengingat,
  NotificationFilter.sistem,
];

/// Menyimpan seluruh preferensi lokal aplikasi (bukan data akun) —
/// notifikasi, tema warna, bahasa, dan zona waktu — dipersist ke
/// SharedPreferences supaya bertahan antar sesi tanpa perlu backend.
class SettingsProvider extends ChangeNotifier {
  static const _kNotificationsEnabled = 'settings_notifications_enabled';
  static const _kSoundEnabled = 'settings_sound_enabled';
  static const _kVibrationEnabled = 'settings_vibration_enabled';
  static const _kRingtone = 'settings_ringtone';
  static const _kCategoryPrefix = 'settings_category_'; // + nama filter
  static const _kAccentColor = 'settings_accent_color';
  static const _kLanguage = 'settings_language';
  static const _kTimezone = 'settings_timezone';
  static const _kAppLockEnabled = 'settings_app_lock_enabled';
  static const _kPinHash = 'settings_pin_hash';

  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _ringtone = kRingtoneOptions.first;
  final Map<NotificationFilter, bool> _categoryEnabled = {
    for (final c in kToggleableCategories) c: true,
  };
  AppAccentColor _accentColor = AppAccentColor.ungu;
  String _language = 'Bahasa Indonesia';
  String _timezone = kTimezoneOptions.first;
  bool _appLockEnabled = false;
  String? _pinHash;

  bool _loaded = false;

  SettingsProvider() {
    _load();
  }

  bool get isLoaded => _loaded;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  String get ringtone => _ringtone;
  AppAccentColor get accentColor => _accentColor;
  String get language => _language;
  String get timezone => _timezone;

  /// True kalau user sudah mengaktifkan kunci PIN untuk membuka aplikasi.
  bool get appLockEnabled => _appLockEnabled && _pinHash != null;

  /// True kalau sudah pernah ada PIN tersimpan (dipakai buat cek apakah
  /// ini setup PIN pertama kali atau ubah PIN yang sudah ada).
  bool get hasPinSet => _pinHash != null;

  bool isCategoryEnabled(NotificationFilter filter) =>
      _categoryEnabled[filter] ?? true;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    _notificationsEnabled = prefs.getBool(_kNotificationsEnabled) ?? true;
    _soundEnabled = prefs.getBool(_kSoundEnabled) ?? true;
    _vibrationEnabled = prefs.getBool(_kVibrationEnabled) ?? true;
    _ringtone = prefs.getString(_kRingtone) ?? kRingtoneOptions.first;

    for (final category in kToggleableCategories) {
      _categoryEnabled[category] =
          prefs.getBool('$_kCategoryPrefix${category.name}') ?? true;
    }

    final savedAccentIndex = prefs.getInt(_kAccentColor);
    if (savedAccentIndex != null &&
        savedAccentIndex < AppAccentColor.values.length) {
      _accentColor = AppAccentColor.values[savedAccentIndex];
    }

    _language = prefs.getString(_kLanguage) ?? 'Bahasa Indonesia';
    _timezone = prefs.getString(_kTimezone) ?? kTimezoneOptions.first;
    _appLockEnabled = prefs.getBool(_kAppLockEnabled) ?? false;
    _pinHash = prefs.getString(_kPinHash);

    _loaded = true;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabled, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSoundEnabled, value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kVibrationEnabled, value);
  }

  Future<void> setRingtone(String value) async {
    _ringtone = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRingtone, value);
  }

  Future<void> setCategoryEnabled(NotificationFilter filter, bool value) async {
    _categoryEnabled[filter] = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kCategoryPrefix${filter.name}', value);
  }

  Future<void> setAccentColor(AppAccentColor value) async {
    _accentColor = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAccentColor, value.index);
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, value);
  }

  Future<void> setTimezone(String value) async {
    _timezone = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTimezone, value);
  }

  /// Menyimpan PIN baru (4-6 digit) dan langsung mengaktifkan kunci
  /// aplikasi. PIN tidak disimpan mentah — hanya hash lokalnya (lihat
  /// [_hashPin]) yang dipersist ke SharedPreferences.
  Future<void> setPin(String pin) async {
    _pinHash = _hashPin(pin);
    _appLockEnabled = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPinHash, _pinHash!);
    await prefs.setBool(_kAppLockEnabled, true);
  }

  /// Membandingkan PIN yang diketik user dengan hash tersimpan.
  bool verifyPin(String pin) => _pinHash != null && _pinHash == _hashPin(pin);

  /// Mematikan kunci PIN dan menghapus hash tersimpan sepenuhnya — supaya
  /// mengaktifkan lagi nanti selalu berarti bikin PIN baru.
  Future<void> disableAppLock() async {
    _appLockEnabled = false;
    _pinHash = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAppLockEnabled, false);
    await prefs.remove(_kPinHash);
  }

  /// Toggle aktif/nonaktif tanpa menghapus PIN yang sudah ada (dipakai
  /// kalau user mau matikan kunci sementara tapi PIN-nya tetap tersimpan
  /// untuk dipakai lagi nanti). Tidak dipakai dari UI saat ini — UI selalu
  /// memilih antara setPin (aktifkan) dan disableAppLock (hapus penuh),
  /// tapi method ini disediakan untuk fleksibilitas ke depan.
  Future<void> setAppLockEnabled(bool value) async {
    if (value && _pinHash == null) return; // tidak ada PIN untuk diaktifkan
    _appLockEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAppLockEnabled, value);
  }

  /// Hash ringan berbasis FNV-1a, murni untuk menghindari menyimpan PIN
  /// dalam bentuk teks polos di SharedPreferences. Ini BUKAN kriptografi
  /// kelas produksi (proyek ini tidak punya akses paket `crypto`/jaringan
  /// untuk `pub get`) — cukup untuk model ancaman "orang lain mengintip
  /// PIN di storage lokal", bukan untuk melindungi data sensitif lain.
  String _hashPin(String pin) {
    const seed = 0x811C9DC5;
    const prime = 0x01000193;
    var hash = seed;
    for (final unit in utf8.encode('edutrack_pin_salt::$pin')) {
      hash ^= unit;
      hash = (hash * prime) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
