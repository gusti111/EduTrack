import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Background gradient + dekorasi lingkaran/titik yang dipakai bersama di
/// semua layar auth (Login, Register, Lupa Password) supaya nyambung
/// secara visual dengan [SplashScreen] — satu tempat, bukan disalin-tempel
/// tiap screen.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            top: -60,
            right: -50,
            child: _decorCircle(150, AppColors.primary.withValues(alpha: 0.10)),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: _decorCircle(220, AppColors.secondary.withValues(alpha: 0.14)),
          ),
          Positioned(top: 26, left: 24, child: _dotsGrid()),
          Positioned(bottom: 140, right: 24, child: _dotsGrid()),
          SafeArea(child: child),
        ],
      ),
    );
  }

  static Widget _decorCircle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  static Widget _dotsGrid() {
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

/// Logo EduTrack (kotak ungu + ikon graduation cap) + judul & tagline,
/// dipakai berulang di Login/Register/Splash.
class AuthLogoHeader extends StatelessWidget {
  const AuthLogoHeader({super.key, this.compact = false});

  /// Versi lebih kecil dipakai di Register (biar form muat tanpa scroll
  /// berlebihan).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 72.0 : 88.0;
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.30),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(Icons.school, color: Colors.white, size: size * 0.5),
        ),
        SizedBox(height: compact ? 12 : 16),
        Text(
          'EduTrack',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          'Smart Student Planner',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondaryOf(context)),
        ),
      ],
    );
  }
}

/// Tombol "Login dengan Google" bergaya outline putih sesuai Figma.
/// Sudah terhubung ke [AuthProvider.loginWithGoogle] — di Web pakai popup
/// Firebase langsung, di Android/iOS pakai package google_sign_in.
/// AuthGate (SplashScreen) yang akan otomatis pindah layar begitu login
/// berhasil, jadi tombol ini tidak perlu Navigator manual.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  Future<void> _handleTap(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithGoogle();

    if (!context.mounted || success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(auth.failure?.message ?? 'Login Google gagal')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<AuthProvider>().isSubmitting;

    return OutlinedButton.icon(
      onPressed: isSubmitting ? null : () => _handleTap(context),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surfaceOf(context),
        side: BorderSide(color: AppColors.dividerOf(context)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: isSubmitting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const _GoogleG(),
      label: Text(
        isSubmitting ? 'Menghubungkan...' : 'Login dengan Google',
        style: TextStyle(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// "G" berwarna ala logo Google, dibuat dari teks supaya tidak perlu aset
/// gambar tambahan.
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 16,
        color: Color(0xFF4285F4),
      ),
    );
  }
}

/// Divider "atau" di antara form dan tombol Google.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.dividerOf(context))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('atau', style: TextStyle(color: AppColors.textSecondaryOf(context))),
        ),
        Expanded(child: Divider(color: AppColors.dividerOf(context))),
      ],
    );
  }
}
