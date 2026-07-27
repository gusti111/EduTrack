import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import 'widgets/pin_keypad.dart';

/// Ditampilkan di depan [HomeShell] setiap kali app dibuka/di-resume saat
/// `SettingsProvider.appLockEnabled` aktif. User harus mengetik PIN yang
/// benar dulu sebelum [onUnlocked] dipanggil (biasanya cuma menghilangkan
/// layar ini lewat state di pemanggilnya).
class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  static const _pinLength = 4;

  String _input = '';
  bool _hasError = false;

  void _onDigit(String digit) {
    if (_input.length >= _pinLength) return;
    setState(() {
      _hasError = false;
      _input += digit;
    });
    if (_input.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 120), _verify);
    }
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _verify() async {
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    if (settings.verifyPin(_input)) {
      widget.onUnlocked();
    } else {
      setState(() => _hasError = true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _input = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.primaryLightOf(context),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 34),
              ),
              const SizedBox(height: 20),
              Text(
                'Masukkan PIN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aplikasi terkunci. Masukkan PIN untuk melanjutkan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context)),
              ),
              const SizedBox(height: 28),
              PinDots(length: _pinLength, filled: _input.length, hasError: _hasError),
              if (_hasError) ...[
                const SizedBox(height: 10),
                const Text(
                  'PIN salah, coba lagi',
                  style: TextStyle(color: AppColors.danger, fontSize: 12.5),
                ),
              ],
              const Spacer(),
              PinNumberPad(onDigit: _onDigit, onBackspace: _onBackspace),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.read<AuthProvider>().logout(),
                child: const Text('Keluar dari akun ini'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
