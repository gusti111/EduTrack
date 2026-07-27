import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/validator.dart';
import '../../core/widgets/auth_background.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi kata sandi tidak boleh kosong';
    }
    if (value != _passwordController.text) {
      return 'Konfirmasi kata sandi tidak sama';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _emailController.text.trim(),
      _passwordController.text,
      displayName: _nameController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context); // AuthGate akan otomatis pindah ke Home
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.failure?.message ?? 'Gagal mendaftar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<AuthProvider>().isSubmitting;

    return Scaffold(
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthLogoHeader(compact: true),
                  const SizedBox(height: 24),
                  Text(
                    'Buat Akun Baru',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Isi data berikut untuk membuat akun EduTrack',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondaryOf(context)),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _nameController,
                    label: 'Nama Lengkap',
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: Validators.name,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Kata Sandi',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    validator: Validators.strongPassword,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Konfirmasi Kata Sandi',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: _confirmPasswordValidator,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLightOf(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.verified_user_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kata sandi minimal 6 karakter dengan kombinasi '
                            'huruf besar, huruf kecil, dan angka',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Daftar'),
                  ),
                  const SizedBox(height: 20),
                  const OrDivider(),
                  const SizedBox(height: 20),
                  const GoogleSignInButton(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sudah punya akun?'),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
