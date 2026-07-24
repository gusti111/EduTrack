import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../providers/theme_provider.dart';

/// Versi awal: notifikasi masih di state lokal (belum persist).
/// Kalau mau persist antar sesi, sambungkan ke `SharedPreferences`
/// (lihat Jobsheet 12) lewat provider terpisah, mis. `SettingsProvider`.
/// Mode gelap sudah tersambung ke [ThemeProvider] (global, lewat MultiProvider).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Notifikasi'),
            subtitle: const Text('Tampilkan notifikasi tugas mendekati tenggat'),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Mode Gelap'),
            subtitle: const Text('Berlaku untuk seluruh aplikasi'),
            value: themeProvider.isDarkMode,
            onChanged: (_) => themeProvider.toggle(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang EduTrack'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRoutes.about),
          ),
        ],
      ),
    );
  }
}
