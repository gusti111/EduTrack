import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../repositories/auth_repository.dart';
import '../security/pin_setup_screen.dart';

/// Sub-halaman "Keamanan Akun". Ubah password memakai jalur reset-lewat-
/// email yang sudah ada di [AuthRepository] (Firebase tidak mengizinkan
/// ubah password langsung tanpa re-autentikasi baru-baru ini, dan jalur
/// email adalah cara paling aman & standar tanpa perlu form
/// re-autentikasi terpisah).
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _sending = false;

  /// Toggle "Kunci Aplikasi (PIN)". Menyalakan -> buka PinSetupScreen untuk
  /// membuat PIN baru (toggle baru benar-benar aktif kalau setup berhasil).
  /// Mematikan -> minta konfirmasi, lalu hapus PIN tersimpan sepenuhnya.
  Future<void> _onAppLockChanged(bool value) async {
    final settings = context.read<SettingsProvider>();
    if (value) {
      final created = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      );
      // Tidak perlu setState manual — SettingsProvider sudah notifyListeners
      // saat PIN berhasil disimpan, dan screen ini watch provider itu.
      if (created != true) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Matikan Kunci Aplikasi?'),
          content: const Text(
            'PIN yang tersimpan akan dihapus. Kamu perlu membuat PIN baru '
            'kalau ingin mengaktifkan kunci aplikasi lagi nanti.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Matikan'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await settings.disableAppLock();
      }
    }
  }

  Future<void> _sendResetLink() async {
    final authRepository = context.read<AuthRepository>();
    final email = authRepository.currentEmail;
    if (email == null) return;

    setState(() => _sending = true);
    try {
      await authRepository.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link ubah password sudah dikirim ke $email')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim link. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.read<AuthRepository>().currentEmail ?? '-';
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(title: const Text('Keamanan Akun')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLightOf(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Ubah Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Demi keamanan, tautan untuk mengganti password akan dikirim ke email akunmu:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryOf(context)),
                ),
                const SizedBox(height: 6),
                Text(email, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _sending ? null : _sendResetLink,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_sending ? 'Mengirim...' : 'Kirim Link Ubah Password'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pin_outlined, color: AppColors.info, size: 20),
              ),
              title: const Text('Kunci Aplikasi (PIN)', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                settings.appLockEnabled
                    ? 'Aktif — PIN diminta setiap kali membuka aplikasi'
                    : 'Kunci aplikasi dengan PIN 4 digit',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context)),
              ),
              value: settings.appLockEnabled,
              onChanged: _onAppLockChanged,
            ),
          ),
          if (settings.appLockEnabled) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PinSetupScreen()),
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Ubah PIN'),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 18, color: AppColors.danger),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Jangan bagikan link ubah password ke siapa pun. Kalau kamu tidak meminta ini, abaikan email tersebut.',
                    style: TextStyle(fontSize: 12, color: AppColors.danger, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout, color: AppColors.danger, size: 18),
              label: const Text('Keluar dari akun ini', style: TextStyle(color: AppColors.danger)),
            ),
          ),
        ],
      ),
    );
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
