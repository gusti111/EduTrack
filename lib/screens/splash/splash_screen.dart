import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../auth/login_screen.dart';
import '../home/home_shell.dart';
import '../security/pin_lock_screen.dart';

/// Splash sekaligus AuthGate: menampilkan logo, mengecek status login lewat
/// [AuthProvider], lalu mengarahkan ke [LoginScreen] atau [HomeShell].
///
/// Ini satu-satunya tempat yang perlu tahu soal AuthStatus — layar lain
/// tinggal terima `uid` yang sudah pasti ada.
///
/// [_minSplashDuration] sengaja menahan splash tampil minimal sekian lama
/// supaya logo tidak "kedip" sekilas kalau AuthProvider kebetulan sudah tahu
/// status login dalam hitungan milidetik. Kalau pengecekan status login
/// ternyata lebih lama dari durasi minimal, splash otomatis menunggu sampai
/// AuthStatus beres duluan — bukan malah dipotong.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Diperpanjang jadi 7 detik (dalam rentang 6-8 detik yang diminta) supaya
  // brand EduTrack sempat "kebaca" tanpa terasa lambat. Animasi logo tetap
  // singkat (900ms) lalu diam di posisi akhirnya sampai durasi ini lewat.
  static const _minSplashDuration = Duration(seconds: 7);

  // Pesan singkat yang berganti-ganti selama splash tampil, supaya durasi
  // yang lebih panjang (7 detik) terasa seperti "sedang menyiapkan sesuatu"
  // alih-alih cuma diam menunggu.
  static const _loadingMessages = [
    'Menyiapkan akun kamu...',
    'Menyusun jadwal & tugasmu...',
    'Hampir siap, semangat belajar!',
  ];

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _minDurationElapsed = false;
  int _messageIndex = 0;
  Timer? _messageTimer;

  // True setelah user berhasil mengetik PIN yang benar di PinLockScreen.
  // Direset ke false saat logout supaya sesi login berikutnya diminta PIN
  // lagi (kalau app lock masih aktif).
  bool _unlockedThisSession = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    Timer(_minSplashDuration, () {
      if (mounted) setState(() => _minDurationElapsed = true);
    });

    _messageTimer = Timer.periodic(const Duration(milliseconds: 2300), (_) {
      if (!mounted) return;
      setState(() => _messageIndex = (_messageIndex + 1) % _loadingMessages.length);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Mengarahkan ke Login/Home hanya kalau status sudah diketahui DAN
    // durasi minimal splash sudah lewat.
    if (_minDurationElapsed) {
      switch (auth.status) {
        case AuthStatus.unauthenticated:
          if (_unlockedThisSession) _unlockedThisSession = false;
          return const LoginScreen();
        case AuthStatus.authenticated:
          final settings = context.watch<SettingsProvider>();
          if (settings.appLockEnabled && !_unlockedThisSession) {
            return PinLockScreen(
              onUnlocked: () => setState(() => _unlockedThisSession = true),
            );
          }
          return HomeShell(uid: auth.uid!);
        case AuthStatus.unknown:
          break; // lanjut tampilkan splash di bawah
      }
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryLightOf(context), AppColors.bg(context)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: _decorCircle(140, AppColors.primary.withValues(alpha: 0.10)),
            ),
            Positioned(
              bottom: -90,
              left: -60,
              child: _decorCircle(200, AppColors.secondary.withValues(alpha: 0.14)),
            ),
            Positioned(top: 28, left: 24, child: _dotsGrid()),
            Positioned(bottom: 40, right: 28, child: _dotsGrid()),
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'EduTrack',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Smart Student Planner',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondaryOf(context),
                              ),
                        ),
                        const SizedBox(height: 44),
                        SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _loadingMessages[_messageIndex],
                            key: ValueKey(_messageIndex),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondaryOf(context),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  Widget _dotsGrid() {
    return Column(
      children: List.generate(
        3,
        (row) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: List.generate(
              3,
              (col) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
