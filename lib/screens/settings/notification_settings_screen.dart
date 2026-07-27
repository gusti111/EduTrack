import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../models/notification_type.dart';
import '../../providers/settings_provider.dart';

/// Sub-halaman "Notifikasi": toggle utama, section "Nada & Getaran"
/// (suara, pilih nada dering via bottom sheet dengan preview, getaran),
/// section "Kategori Notifikasi" (4 toggle sesuai grup filter di
/// NotificationScreen), dan info box izin sistem — semua opsi turunan
/// otomatis redup/nonaktif kalau toggle utama mati.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final enabled = settings.notificationsEnabled;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(title: const Text('Notifikasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerOf(context)),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLightOf(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
              ),
              title: const Text('Aktifkan Notifikasi', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                'Matikan untuk menonaktifkan semua notifikasi EduTrack',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context)),
              ),
              value: enabled,
              onChanged: settings.setNotificationsEnabled,
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('NADA & GETARAN', enabled: enabled),
          _SectionCard(
            enabled: enabled,
            children: [
              _SwitchRow(
                icon: Icons.volume_up_rounded,
                iconColor: AppColors.info,
                title: 'Suara',
                subtitle: 'Bunyikan nada saat notifikasi masuk',
                value: settings.soundEnabled,
                enabled: enabled,
                onChanged: settings.setSoundEnabled,
              ),
              const _MenuDivider(),
              _TapRow(
                icon: Icons.music_note_rounded,
                iconColor: AppColors.secondary,
                title: 'Pilih Nada Dering',
                subtitle: 'Nada yang dipakai saat notifikasi masuk',
                trailingText: settings.ringtone,
                enabled: enabled && settings.soundEnabled,
                onTap: () => _showRingtonePicker(context, settings),
              ),
              const _MenuDivider(),
              _SwitchRow(
                icon: Icons.vibration_rounded,
                iconColor: AppColors.warning,
                title: 'Getaran',
                subtitle: 'Getarkan perangkat saat notifikasi masuk',
                value: settings.vibrationEnabled,
                enabled: enabled,
                onChanged: (value) {
                  settings.setVibrationEnabled(value);
                  // Kasih umpan balik getaran langsung saat dinyalakan, biar
                  // user merasakan efeknya seketika alih-alih cuma teks.
                  if (value) HapticFeedback.mediumImpact();
                },
              ),
              if (enabled && settings.vibrationEnabled) ...[
                const _MenuDivider(),
                _TapRow(
                  icon: Icons.touch_app_rounded,
                  iconColor: AppColors.warning,
                  title: 'Uji Getaran',
                  subtitle: 'Rasakan pola getaran notifikasi',
                  trailingText: '',
                  enabled: enabled,
                  onTap: () => HapticFeedback.heavyImpact(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _SectionLabel('KATEGORI NOTIFIKASI', enabled: enabled),
          _SectionCard(
            enabled: enabled,
            children: [
              for (final category in kToggleableCategories) ...[
                _SwitchRow(
                  icon: _categoryIcon(category),
                  iconColor: _categoryColor(context, category),
                  title: category.label,
                  subtitle: _categorySubtitle(category),
                  value: settings.isCategoryEnabled(category),
                  enabled: enabled,
                  onChanged: (value) => settings.setCategoryEnabled(category, value),
                ),
                if (category != kToggleableCategories.last) const _MenuDivider(),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pastikan izin notifikasi EduTrack juga diaktifkan di Pengaturan Sistem perangkatmu agar notifikasi tetap muncul saat aplikasi tertutup.',
                    style: TextStyle(fontSize: 12, color: AppColors.info.withValues(alpha: 0.9), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(NotificationFilter filter) => switch (filter) {
        NotificationFilter.tugas => Icons.menu_book_rounded,
        NotificationFilter.jadwal => Icons.science_rounded,
        NotificationFilter.pengingat => Icons.notifications_rounded,
        NotificationFilter.sistem => Icons.settings_suggest_rounded,
        NotificationFilter.semua => Icons.notifications_rounded,
      };

  Color _categoryColor(BuildContext context, NotificationFilter filter) => switch (filter) {
        NotificationFilter.tugas => AppColors.primary,
        NotificationFilter.jadwal => AppColors.warning,
        NotificationFilter.pengingat => AppColors.info,
        NotificationFilter.sistem => AppColors.textSecondaryOf(context),
        NotificationFilter.semua => AppColors.primary,
      };

  String _categorySubtitle(NotificationFilter filter) => switch (filter) {
        NotificationFilter.tugas => 'Deadline, tugas selesai, dan tugas terlambat',
        NotificationFilter.jadwal => 'Jadwal kuliah dan praktikum',
        NotificationFilter.pengingat => 'Pengingat belajar dan ujian',
        NotificationFilter.sistem => 'Pengumuman dan info sistem',
        NotificationFilter.semua => '',
      };

  /// Pratinjau nada dering pakai umpan balik bawaan Flutter
  /// (`SystemSound`/`HapticFeedback`) — proyek ini tidak punya asset audio
  /// sungguhan per nada dan tidak ada akses jaringan untuk `pub get` paket
  /// pemutar audio baru, jadi preview memakai kombinasi bunyi sistem +
  /// getaran supaya tombolnya benar-benar berefek, bukan cuma snackbar.
  Future<void> _previewRingtone(BuildContext context, String tone) async {
    if (tone == 'Tanpa Suara') {
      HapticFeedback.selectionClick();
    } else {
      await SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pratinjau nada "$tone"'), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _showRingtonePicker(BuildContext context, SettingsProvider settings) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.dividerOf(ctx),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Pilih Nada Dering', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                const SizedBox(height: 8),
                for (final tone in kRingtoneOptions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      tone == 'Tanpa Suara' ? Icons.volume_off_rounded : Icons.music_note_rounded,
                      color: settings.ringtone == tone ? AppColors.primary : AppColors.textSecondaryOf(ctx),
                    ),
                    title: Text(tone, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: settings.ringtone == tone
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                        : IconButton(
                            icon: Icon(Icons.play_circle_outline_rounded, color: AppColors.textSecondaryOf(ctx)),
                            tooltip: 'Pratinjau',
                            onPressed: () => _previewRingtone(ctx, tone),
                          ),
                    onTap: () {
                      settings.setRingtone(tone);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.enabled});
  final String text;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: enabled ? AppColors.primary : AppColors.textSecondaryOf(context),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children, required this.enabled});
  final List<Widget> children;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.45,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dividerOf(context)),
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1);
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _TapRow extends StatelessWidget {
  const _TapRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailingText;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText.isNotEmpty) ...[
            Text(trailingText, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12.5)),
            const SizedBox(width: 4),
          ],
          Icon(Icons.chevron_right, color: AppColors.textSecondaryOf(context)),
        ],
      ),
      onTap: enabled ? onTap : null,
    );
  }
}
