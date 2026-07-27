import 'package:flutter/material.dart';

import '../screens/about/about_screen.dart';
import '../screens/settings/language_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/settings/privacy_screen.dart';
import '../screens/settings/security_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/theme_color_screen.dart';
import '../screens/settings/timezone_screen.dart';

/// Nama route dipusatkan di sini biar tidak ada magic string tersebar.
///
/// Catatan: sebagian besar screen di EduTrack butuh argumen wajib yang
/// bertipe kuat (mis. `TaskDetailScreen(task: task)`,
/// `AddEditTaskScreen(uid: uid)`) — untuk itu, `Navigator.push` +
/// `MaterialPageRoute` langsung di call-site (seperti yang sudah dipakai
/// sekarang) tetap cara yang paling aman: argumen dicek compiler, bukan
/// di-cast manual dari `Object?` seperti kalau dipaksa lewat
/// `Navigator.pushNamed(arguments: ...)`.
///
/// Named routes di sini sengaja dibatasi ke screen yang **tidak butuh
/// argumen**, di mana named routes justru lebih ringkas dipakai.
class AppRoutes {
  AppRoutes._();

  static const String settings = '/settings';
  static const String about = '/about';
  static const String notificationSettings = '/settings/notifications';
  static const String security = '/settings/security';
  static const String privacy = '/settings/privacy';
  static const String themeColor = '/settings/theme-color';
  static const String language = '/settings/language';
  static const String timezone = '/settings/timezone';

  static Map<String, WidgetBuilder> get routes => {
        settings: (_) => const SettingsScreen(),
        about: (_) => const AboutScreen(),
        notificationSettings: (_) => const NotificationSettingsScreen(),
        security: (_) => const SecurityScreen(),
        privacy: (_) => const PrivacyScreen(),
        themeColor: (_) => const ThemeColorScreen(),
        language: (_) => const LanguageScreen(),
        timezone: (_) => const TimezoneScreen(),
      };
}
