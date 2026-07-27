import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/errors/failure.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/task_status.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../repositories/auth_repository.dart';
import 'edit_profile_screen.dart';

/// Halaman Profil, dirombak mengikuti desain Figma: header gradient ungu
/// dengan avatar & badge status, ringkasan aktivitas (dari TaskProvider yang
/// sama dipakai di HomeScreen/StatisticsScreen), lalu detail diri (gender,
/// usia, status, semester) dan menu cepat.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Future disimpan di State (bukan dibuat langsung di build) supaya tidak
  // memicu request baru ke Firestore setiap kali widget rebuild — hanya
  // dibuat ulang saat kita eksplisit memanggil _loadProfile().
  Future<UserModel?>? _profileFuture;
  String? _loadedForUid;

  void _loadProfile(String uid) {
    final authRepository = context.read<AuthRepository>();
    setState(() {
      _loadedForUid = uid;
      _profileFuture = authRepository.getUserProfile(uid);
    });
  }

  void _loadProfileSilently(String uid) {
    final authRepository = context.read<AuthRepository>();
    _loadedForUid = uid;
    _profileFuture = authRepository.getUserProfile(uid);
  }

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().uid;
    if (uid != null) {
      _loadProfileSilently(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();
    final uid = context.watch<AuthProvider>().uid;

    if (uid == null) {
      return const Scaffold(body: LoadingWidget());
    }

    if (_loadedForUid != uid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadProfile(uid);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: FutureBuilder<UserModel?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          if (snapshot.hasError) {
            final failure = snapshot.error is Failure
                ? snapshot.error as Failure
                : const UnknownFailure();
            return ErrorState(failure: failure, onRetry: () => _loadProfile(uid));
          }

          final profile = snapshot.data;
          final email = authRepository.currentEmail ?? '-';
          final displayName = profile?.displayName ?? 'Pengguna EduTrack';
          final status = profile?.status ?? UserStatus.mahasiswa;

          return RefreshIndicator(
            onRefresh: () async => _loadProfile(uid),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _ProfileHeader(
                  displayName: displayName,
                  email: email,
                  status: status,
                  onSettingsTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                  onEditTap: () => _openEditProfile(context, uid, email, profile),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ringkasan Aktivitas',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  )),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _ActivitySummaryRow(),
                      const SizedBox(height: 24),
                      _DetailCard(profile: profile),
                      const SizedBox(height: 24),
                      Text('Menu Cepat',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              )),
                      const SizedBox(height: 12),
                      _MenuTile(
                        icon: Icons.edit_outlined,
                        title: 'Edit Profil',
                        subtitle: 'Ubah data diri & informasi akademik',
                        onTap: () => _openEditProfile(context, uid, email, profile),
                      ),
                      const SizedBox(height: 10),
                      _MenuTile(
                        icon: Icons.settings_outlined,
                        title: 'Pengaturan',
                        subtitle: 'Notifikasi, tema, bahasa, & keamanan',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                      ),
                      const SizedBox(height: 10),
                      _MenuTile(
                        icon: Icons.info_outline,
                        title: 'Tentang Aplikasi',
                        subtitle: 'Versi & kebijakan EduTrack',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                      ),
                      const SizedBox(height: 20),
                      _MenuTile(
                        icon: Icons.logout,
                        title: 'Keluar',
                        subtitle: 'Keluar dari akun EduTrack',
                        color: AppColors.danger,
                        onTap: () => _confirmLogout(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditProfile(
    BuildContext context,
    String uid,
    String email,
    UserModel? profile,
  ) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(uid: uid, email: email, profile: profile),
      ),
    );
    if (updated == true && mounted) {
      _loadProfile(uid);
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu perlu login ulang untuk mengakses EduTrack.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.status,
    required this.onSettingsTap,
    required this.onEditTap,
  });

  final String displayName;
  final String email;
  final String status;
  final VoidCallback onSettingsTap;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, bottom: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Text('Profil',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        )),
                IconButton(
                  onPressed: onSettingsTap,
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 39,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEditTap,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: const Icon(Icons.edit, size: 14, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(email, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(status, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivitySummaryRow extends StatelessWidget {
  const _ActivitySummaryRow();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final total = provider.tasks.length;
    final completed = provider.tasksByStatus(TaskStatus.completed).length;
    final inProgress = provider.tasksByStatus(TaskStatus.inProgress).length;
    final overdue = provider.tasksByStatus(TaskStatus.overdue).length;

    return Row(
      children: [
        Expanded(child: _StatChip(icon: Icons.assignment_outlined, value: total, label: 'Total tugas', color: AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(child: _StatChip(icon: Icons.check_circle, value: completed, label: 'Selesai', color: AppColors.success)),
        const SizedBox(width: 10),
        Expanded(child: _StatChip(icon: Icons.access_time_filled, value: inProgress, label: 'Sedang Dikerjakan', color: AppColors.warning)),
        const SizedBox(width: 10),
        Expanded(child: _StatChip(icon: Icons.error, value: overdue, label: 'Tertunda', color: AppColors.danger)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value, required this.label, required this.color});

  final IconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerOf(context)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: AppColors.textSecondaryOf(context)),
          ),
        ],
      ),
    );
  }
}

/// Kartu "detail diri" — inilah bagian yang menampilkan gender, usia,
/// status, dan semester (kalau Mahasiswa) supaya profil terasa lebih
/// personal & lengkap, bukan cuma nama & email.
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.profile});

  final UserModel? profile;

  @override
  Widget build(BuildContext context) {
    final gender = profile?.gender;
    final age = profile?.age;
    final status = profile?.status ?? UserStatus.mahasiswa;
    final semester = profile?.semester;
    final isMahasiswa = status == UserStatus.mahasiswa;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Detail Diri',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _DetailRow(icon: Icons.wc_outlined, label: 'Jenis Kelamin', value: gender ?? 'Belum diisi'),
          const Divider(height: 20),
          _DetailRow(icon: Icons.cake_outlined, label: 'Usia', value: age != null ? '$age tahun' : 'Belum diisi'),
          const Divider(height: 20),
          _DetailRow(icon: Icons.badge_outlined, label: 'Status', value: status),
          if (isMahasiswa) ...[
            const Divider(height: 20),
            _DetailRow(
              icon: Icons.numbers_outlined,
              label: 'Semester',
              value: semester != null ? 'Semester $semester' : 'Belum diisi',
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13.5)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.primary;
    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color != null ? color!.withValues(alpha: 0.35) : AppColors.dividerOf(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: tint, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: tint == AppColors.danger ? AppColors.danger : AppColors.textPrimaryOf(context))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: tint),
            ],
          ),
        ),
      ),
    );
  }
}
