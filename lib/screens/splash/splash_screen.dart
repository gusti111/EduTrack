import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../home/home_shell.dart';

/// Splash sekaligus AuthGate: selama [AuthStatus.unknown] tampilkan loading,
/// lalu arahkan ke [LoginScreen] atau [HomeShell] sesuai status login.
///
/// Ini satu-satunya tempat yang perlu tahu soal AuthStatus — layar lain
/// tinggal terima `uid` yang sudah pasti ada.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        return HomeShell(uid: auth.uid!);
    }
  }
}
