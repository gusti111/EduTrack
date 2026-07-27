import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import 'widgets/pin_keypad.dart';

/// Layar buat/ubah PIN kunci aplikasi. Alur dua langkah: user mengetik PIN
/// baru (4 digit), lalu diminta mengetik ulang untuk konfirmasi. Kalau
/// keduanya cocok, PIN disimpan (di-hash) lewat [SettingsProvider.setPin]
/// dan layar ini pop dengan hasil `true` supaya SecurityScreen tahu proses
/// berhasil dan bisa memperbarui status toggle-nya.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

enum _PinStep { create, confirm }

class _PinSetupScreenState extends State<PinSetupScreen> {
  static const _pinLength = 4;

  _PinStep _step = _PinStep.create;
  String _firstPin = '';
  String _currentInput = '';
  bool _hasError = false;

  String get _title => _step == _PinStep.create ? 'Buat PIN Baru' : 'Konfirmasi PIN';

  String get _subtitle => _step == _PinStep.create
      ? 'Masukkan $_pinLength digit PIN untuk mengunci aplikasi.'
      : 'Ketik ulang PIN yang sama untuk konfirmasi.';

  void _onDigit(String digit) {
    if (_currentInput.length >= _pinLength) return;
    setState(() {
      _hasError = false;
      _currentInput += digit;
    });
    if (_currentInput.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 150), _handleComplete);
    }
  }

  void _onBackspace() {
    if (_currentInput.isEmpty) return;
    setState(() => _currentInput = _currentInput.substring(0, _currentInput.length - 1));
  }

  Future<void> _handleComplete() async {
    if (!mounted) return;

    if (_step == _PinStep.create) {
      setState(() {
        _firstPin = _currentInput;
        _currentInput = '';
        _step = _PinStep.confirm;
      });
      return;
    }

    // Step konfirmasi
    if (_currentInput == _firstPin) {
      await context.read<SettingsProvider>().setPin(_currentInput);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunci PIN berhasil diaktifkan')),
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        _hasError = true;
        _currentInput = '';
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      // PIN konfirmasi tidak cocok -> ulang dari awal, bukan cuma step
      // konfirmasi, supaya user tidak "terkunci" pada PIN pertama yang
      // mungkin salah ketik.
      setState(() {
        _hasError = false;
        _firstPin = '';
        _step = _PinStep.create;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(title: const Text('Kunci Aplikasi')),
      body: Padding(
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
              _title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: 28),
            PinDots(length: _pinLength, filled: _currentInput.length, hasError: _hasError),
            if (_hasError) ...[
              const SizedBox(height: 10),
              const Text(
                'PIN tidak cocok, coba lagi dari awal',
                style: TextStyle(color: AppColors.danger, fontSize: 12.5),
              ),
            ],
            const Spacer(),
            PinNumberPad(onDigit: _onDigit, onBackspace: _onBackspace),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
