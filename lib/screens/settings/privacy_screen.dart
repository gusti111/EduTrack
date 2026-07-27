import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_colors.dart';

/// Sub-halaman "Privasi". Preferensi di sini murni lokal (disimpan di
/// perangkat lewat SharedPreferences) — belum ada backend analitik
/// sungguhan di project ini, jadi tidak jujur kalau berpura-pura toggle
/// ini mengubah sesuatu di server. Yang ditawarkan hanya yang benar-benar
/// bisa dipenuhi: preferensi lokal + transparansi data apa yang disimpan.
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  static const _kAnalytics = 'privacy_analytics_enabled';
  static const _kPersonalization = 'privacy_personalization_enabled';

  bool _loaded = false;
  bool _analyticsEnabled = true;
  bool _personalizationEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _analyticsEnabled = prefs.getBool(_kAnalytics) ?? true;
      _personalizationEnabled = prefs.getBool(_kPersonalization) ?? true;
      _loaded = true;
    });
  }

  Future<void> _setAnalytics(bool value) async {
    setState(() => _analyticsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAnalytics, value);
  }

  Future<void> _setPersonalization(bool value) async {
    setState(() => _personalizationEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPersonalization, value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(title: const Text('Privasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerOf(context)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.query_stats_rounded, color: AppColors.primary),
                  title: const Text('Analitik Penggunaan', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Bantu perbaikan EduTrack dengan data pemakaian anonim',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context)),
                  ),
                  value: _analyticsEnabled,
                  onChanged: _setAnalytics,
                ),
                const Divider(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.auto_awesome_rounded, color: AppColors.warning),
                  title: const Text('Personalisasi', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Sesuaikan rekomendasi belajar dengan kebiasaanmu',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context)),
                  ),
                  value: _personalizationEnabled,
                  onChanged: _setPersonalization,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _InfoTile(
            icon: Icons.storage_rounded,
            title: 'Data yang Disimpan',
            body: 'Nama, email, foto profil, daftar tugas, dan jadwal kuliah — tersimpan aman di akun Firebase-mu.',
          ),
          const SizedBox(height: 12),
          const _InfoTile(
            icon: Icons.share_rounded,
            title: 'Berbagi Data',
            body: 'EduTrack tidak membagikan data pribadimu ke pihak ketiga untuk kepentingan iklan.',
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => _showDeleteAccountInfo(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus Akun'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: const Text(
          'Untuk menghapus akun beserta seluruh datamu secara permanen, silakan hubungi tim dukungan '
          'EduTrack lewat menu Bantuan & Dukungan di halaman Profil. Kami akan memprosesnya dalam 1x24 jam.',
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti')),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerOf(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondaryOf(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
