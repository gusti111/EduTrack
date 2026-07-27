import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/validator.dart';
import '../../core/widgets/auth_background.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.sendPasswordReset(_emailController.text.trim());

    if (!mounted) return;
    if (success) {
      setState(() => _emailSent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.failure?.message ?? 'Gagal mengirim email')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<AuthProvider>().isSubmitting;

    return Scaffold(
      body: AuthBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceOf(context),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const _ForgotPasswordIllustration(),
              const SizedBox(height: 24),
              if (_emailSent) _buildSentState(context) else _buildForm(isSubmitting),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isSubmitting) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Lupa Password',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Jangan khawatir! Masukkan email akun Anda dan kami akan '
            'mengirimkan link untuk mereset password.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_outlined, size: 18),
            label: Text(isSubmitting ? 'Mengirim...' : 'Kirim Reset Password'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLightOf(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Link reset password akan dikirim ke email Anda dalam '
                    'beberapa menit. Periksa juga folder spam jika tidak '
                    'muncul di inbox.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const OrDivider(),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Kembali Ke Login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 64, color: AppColors.success),
        const SizedBox(height: 16),
        Text(
          'Link reset kata sandi sudah dikirim ke '
          '${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kembali ke Login'),
        ),
      ],
    );
  }
}

/// Ilustrasi amplop + gembok + tanda tanya, dibuat dari ikon-ikon Material
/// (bukan aset gambar) supaya tidak butuh file tambahan, tapi tetap
/// menangkap nuansa ilustrasi di desain Figma.
class _ForgotPasswordIllustration extends StatelessWidget {
  const _ForgotPasswordIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 120,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primaryLightOf(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.mail_outline, size: 48, color: AppColors.primary),
            ),
            Positioned(
              top: -8,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_outline, color: Colors.white, size: 22),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 12,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.question_mark_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
