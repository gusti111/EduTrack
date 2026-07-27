import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../providers/settings_provider.dart';

/// Sub-halaman "Zona Waktu" — daftar 3 zona waktu Indonesia, disimpan
/// sebagai preferensi tampilan (dipakai kalau nanti butuh tampilkan jam
/// lokal user selain WIB).
class TimezoneScreen extends StatelessWidget {
  const TimezoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(title: const Text('Zona Waktu')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: kTimezoneOptions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final option = kTimezoneOptions[index];
          final selected = settings.timezone == option;
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? AppColors.primary : AppColors.dividerOf(context)),
            ),
            child: ListTile(
              leading: const Icon(Icons.public_rounded, color: AppColors.primary),
              title: Text(option, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: selected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
              onTap: () => settings.setTimezone(option),
            ),
          );
        },
      ),
    );
  }
}
