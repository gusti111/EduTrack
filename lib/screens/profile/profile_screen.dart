import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/errors/failure.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/auth_repository.dart';
import 'edit_profile_screen.dart';

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

  /// Dipanggil dari event handler (tombol retry, kembali dari Edit Profil).
  /// AMAN dipanggil setelah build selesai karena selalu dipicu oleh
  /// interaksi user, bukan dari dalam build().
  void _loadProfile(String uid) {
    final authRepository = context.read<AuthRepository>();
    setState(() {
      _loadedForUid = uid;
      _profileFuture = authRepository.getUserProfile(uid);
    });
  }

  /// Memuat profil TANPA setState — hanya boleh dipanggil saat widget belum
  /// selesai di-build (initState) atau di luar fase build (post-frame),
  /// supaya tidak memicu "setState() or markNeedsBuild() called during
  /// build" yang terjadi kalau logic ini dijalankan langsung di build().
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

    // Kasus langka: uid berganti (mis. akun lain login) tanpa remount
    // widget ini. Jadwalkan reload SETELAH frame ini selesai, bukan
    // memanggil setState langsung di sini (itu penyebab bug sebelumnya).
    if (_loadedForUid != uid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadProfile(uid);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
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
            return ErrorState(
              failure: failure,
              onRetry: () => _loadProfile(uid),
            );
          }

          final profile = snapshot.data;
          final email = authRepository.currentEmail ?? '-';
          final displayName = profile?.displayName ?? 'Pengguna EduTrack';

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CircleAvatar(
                radius: 40,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(displayName,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              Center(
                  child: Text(email,
                      style: Theme.of(context).textTheme.bodyMedium)),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Profil'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  // Tunggu hasil edit, lalu muat ulang profil supaya nama
                  // yang baru langsung tampil begitu kembali ke layar ini.
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        uid: uid,
                        currentDisplayName: profile?.displayName ?? '',
                      ),
                    ),
                  );
                  if (updated == true && mounted) {
                    _loadProfile(uid);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Pengaturan'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title:
                    const Text('Keluar', style: TextStyle(color: Colors.red)),
                onTap: () => context.read<AuthProvider>().logout(),
              ),
            ],
          );
        },
      ),
    );
  }
}
