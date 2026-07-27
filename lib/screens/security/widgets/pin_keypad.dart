import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Baris titik indikator panjang PIN yang sudah diketik (mengikuti gaya
/// dot-based PIN entry umum di aplikasi mobile). Dipakai bersama oleh
/// [PinSetupScreen] dan [PinLockScreen] supaya tampilannya konsisten.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.hasError = false,
  });

  final int length;
  final int filled;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final color = hasError ? AppColors.danger : AppColors.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 7),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? color : Colors.transparent,
            border: Border.all(color: color, width: 1.6),
          ),
        );
      }),
    );
  }
}

/// Keypad angka 0-9 + backspace, dipakai untuk input PIN. `onKeyTap`
/// menerima digit sebagai String, dan null khusus untuk tombol backspace.
class PinNumberPad extends StatelessWidget {
  const PinNumberPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final digit in row) _PadKey(label: digit, onTap: () => onDigit(digit)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 72, height: 60),
              _PadKey(label: '0', onTap: () => onDigit('0')),
              _PadKey(
                icon: Icons.backspace_outlined,
                onTap: onBackspace,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({this.label, this.icon, required this.onTap});

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 60,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: icon != null
                ? Icon(icon, color: AppColors.textSecondaryOf(context), size: 22)
                : Text(
                    label!,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
