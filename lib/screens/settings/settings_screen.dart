import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../repositories/auth_repository.dart';
import '../profile/edit_profile_screen.dart';

/// Halaman Pengaturan, dirombak total mengikuti desain Figma: kartu ringkas
/// akun di atas, lalu tiga section (PREFERENSI/KEAMANAN/LAINNYA) berisi
/// menu yang benar-benar mengarah ke sub-halaman fungsional — bukan cuma
/// dua SwitchListTile seperti versi awal.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _profile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final uid = context.read<AuthProvider>().uid;
    if (uid == null) return;
    final profile = await context.read<AuthRepository>().getUserProfile(uid);
    if (mounted) setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();
    final email = context.read<AuthRepository>().currentEmail ?? '-';
    final displayName = _profile?.displayName ?? 'Pengguna EduTrack';
    final status = _profile?.status ?? UserStatus.mahasiswa;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _AccountCard(
            displayName: displayName,
            email: email,
            status: status,
            onTap: () => _openEditProfile(context, email),
          ),
          const SizedBox(height: 22),
          const _SectionLabel('PREFERENSI'),
          _SectionCard(
            children: [
              _MenuTile(
                icon: Icons.notifications_none_rounded,
                iconColor: AppColors.primary,
                title: 'Notifikasi',
                subtitle: 'Kelola pengaturan notifikasi',
                onTap: () => Navigator.pushNamed(context, AppRoutes.notificationSettings),
              ),
              const _MenuDivider(),
              _SwitchTile(
                icon: Icons.dark_mode_outlined,
                iconColor: AppColors.textPrimaryOf(context),
                title: 'Mode Gelap',
                subtitle: 'Aktifkan tampilan gelap',
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggle(),
              ),
              const _MenuDivider(),
              _MenuTile(
                icon: Icons.palette_outlined,
                iconColor: AppColors.secondary,
                title: 'Tema Warna',
                subtitle: 'Pilih tema aplikasi',
                trailingText: settings.accentColor.label,
                onTap: () => Navigator.pushNamed(context, AppRoutes.themeColor),
              ),
              const _MenuDivider(),
              _MenuTile(
                icon: Icons.language_rounded,
                iconColor: AppColors.info,
                title: 'Bahasa',
                subtitle: 'Bahasa aplikasi',
                trailingText: settings.language,
                onTap: () => Navigator.pushNamed(context, AppRoutes.language),
              ),
              const _MenuDivider(),
              _MenuTile(
                icon: Icons.access_time_rounded,
                iconColor: AppColors.warning,
                title: 'Zona Waktu',
                subtitle: settings.timezone,
                onTap: () => Navigator.pushNamed(context, AppRoutes.timezone),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionLabel('KEAMANAN'),
          _SectionCard(
            children: [
              _MenuTile(
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.primary,
                title: 'Keamanan Akun',
                subtitle: 'Ubah password dan verifikasi',
                onTap: () => Navigator.pushNamed(context, AppRoutes.security),
              ),
              const _MenuDivider(),
              _MenuTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: AppColors.success,
                title: 'Privasi',
                subtitle: 'Kelola data dan privasi akun',
                onTap: () => Navigator.pushNamed(context, AppRoutes.privacy),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionLabel('LAINNYA'),
          _SectionCard(
            children: [
              _MenuTile(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.textSecondaryOf(context),
                title: 'Tentang Aplikasi',
                subtitle: 'Informasi versi dan kebijakan',
                onTap: () => Navigator.pushNamed(context, AppRoutes.about),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _LogoutCard(onTap: () => _confirmLogout(context)),
        ],
      ),
    );
  }

  Future<void> _openEditProfile(BuildContext context, String email) async {
    final uid = context.read<AuthProvider>().uid;
    if (uid == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(uid: uid, email: email, profile: _profile),
      ),
    );
    if (updated == true && mounted) _loadProfile();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu perlu login ulang untuk mengakses EduTrack.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthProvider>().logout();
    }
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.displayName,
    required this.email,
    required this.status,
    required this.onTap,
  });

  final String displayName;
  final String email;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerOf(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primaryLightOf(context),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'E',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(email, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightOf(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school, size: 12, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(status,
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
              Icon(Icons.chevron_right, color: AppColors.textSecondaryOf(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerOf(context)),
      ),
      child: Column(children: children),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1);
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? trailingText;
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
          if (trailingText != null) ...[
            Text(trailingText!,
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12.5)),
            const SizedBox(width: 4),
          ],
          Icon(Icons.chevron_right, color: AppColors.textSecondaryOf(context)),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
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
      onChanged: onChanged,
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.danger.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
          ),
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout, color: AppColors.danger),
            title: Text('Logout', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
            subtitle: Text('Keluar dari akun EduTrack', style: TextStyle(fontSize: 12, color: AppColors.danger)),
            trailing: Icon(Icons.chevron_right, color: AppColors.danger),
          ),
        ),
      ),
    );
  }
}
