import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validator.dart';
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
      appBar: AppBar(title: const Text('Lupa Kata Sandi')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _emailSent ? _buildSentState() : _buildForm(isSubmitting),
      ),
    );
  }

  Widget _buildForm(bool isSubmitting) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Masukkan email akun kamu. Kami akan kirim link untuk reset kata sandi.',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isSubmitting ? null : _submit,
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kirim Link Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildSentState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'Link reset kata sandi sudah dikirim ke ${_emailController.text.trim()}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali ke Login'),
          ),
        ],
      ),
    );
  }
}
