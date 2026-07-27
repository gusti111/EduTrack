import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../providers/settings_provider.dart';

/// Sub-halaman "Tema Warna" — mengganti seed color Material di seluruh
/// app secara langsung (lihat SettingsProvider.accentColor & app.dart).
class ThemeColorScreen extends StatelessWidget {
  const ThemeColorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(title: const Text('Tema Warna')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Pilih warna aksen yang dipakai di seluruh tampilan EduTrack.',
            style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppAccentColor.values.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.6,
            ),
            itemBuilder: (context, index) {
              final option = AppAccentColor.values[index];
              final selected = settings.accentColor == option;
              return _AccentTile(
                option: option,
                selected: selected,
                onTap: () => settings.setAccentColor(option),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AccentTile extends StatelessWidget {
  const _AccentTile({required this.option, required this.selected, required this.onTap});

  final AppAccentColor option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? option.color : AppColors.dividerOf(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: option.color, shape: BoxShape.circle),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                option.label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
