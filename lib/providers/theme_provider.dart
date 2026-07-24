import 'package:flutter/material.dart';

/// State sederhana untuk toggle light/dark mode.
/// Sengaja tidak menyentuh Firestore/SharedPreferences dulu — persist ke
/// storage bisa ditambah belakangan lewat StorageService kalau dibutuhkan,
/// tanpa mengubah API provider ini (UI cukup panggil `toggle()`/`setMode()`).
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  bool get isDarkMode => _mode == ThemeMode.dark;

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  void toggle() {
    setMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
}
