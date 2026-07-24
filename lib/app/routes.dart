import 'package:flutter/material.dart';

import '../screens/about/about_screen.dart';
import '../screens/settings/settings_screen.dart';

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

  static Map<String, WidgetBuilder> get routes => {
        settings: (_) => const SettingsScreen(),
        about: (_) => const AboutScreen(),
      };
}
