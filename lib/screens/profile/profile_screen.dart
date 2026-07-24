import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors/failure.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../app/routes.dart';
import '../../repositories/auth_repository.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();
    final uid = context.watch<AuthProvider>().uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: uid == null
          ? const LoadingWidget()
          : FutureBuilder<UserModel?>(
              future: authRepository.getUserProfile(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }
                if (snapshot.hasError) {
                  final failure = snapshot.error is Failure
                      ? snapshot.error as Failure
                      : const UnknownFailure();
                  return ErrorState(failure: failure);
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
                      child: Text(displayName, style: Theme.of(context).textTheme.titleLarge),
                    ),
                    Center(child: Text(email, style: Theme.of(context).textTheme.bodyMedium)),
                    const SizedBox(height: 24),
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Edit Profil'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(
                            uid: uid,
                            currentDisplayName: profile?.displayName ?? '',
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Pengaturan'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Keluar', style: TextStyle(color: Colors.red)),
                      onTap: () => context.read<AuthProvider>().logout(),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
