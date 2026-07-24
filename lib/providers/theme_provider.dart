import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State toggle light/dark mode, dipersist ke SharedPreferences supaya
/// pilihan tema tidak kembali ke default system setiap kali app dibuka
/// ulang. UI tetap cukup panggil `toggle()`/`setMode()` seperti sebelumnya.
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'user_theme_mode';

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  bool get isDarkMode => _mode == ThemeMode.dark;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModeIndex = prefs.getInt(_themeKey);
    if (savedModeIndex != null && savedModeIndex < ThemeMode.values.length) {
      _mode = ThemeMode.values[savedModeIndex];
      notifyListeners();
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  void toggle() {
    setMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
}
