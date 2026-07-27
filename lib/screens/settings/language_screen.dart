import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../providers/settings_provider.dart';

/// Sub-halaman "Bahasa". Konten aplikasi (label, format tanggal id_ID)
/// saat ini sepenuhnya Bahasa Indonesia, jadi opsi lain ditandai "Segera
/// Hadir" alih-alih pura-pura berfungsi tapi tidak benar-benar
/// menerjemahkan apa pun.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  static const _options = [
    ('Bahasa Indonesia', true),
    ('English', false),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(title: const Text('Bahasa')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final (label, available) = _options[index];
          final selected = settings.language == label;
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? AppColors.primary : AppColors.dividerOf(context)),
            ),
            child: ListTile(
              title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: available
                  ? null
                  : Text('Segera hadir', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
              trailing: selected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
              enabled: available,
              onTap: available ? () => settings.setLanguage(label) : null,
            ),
          );
        },
      ),
    );
  }
}
