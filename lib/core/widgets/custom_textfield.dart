import 'package:flutter/material.dart';

/// TextFormField terbungkus dengan style konsisten (icon, border, toggle
/// password) — dipakai di semua screen auth & edit profile supaya tidak
/// menyalin dekorasi `InputDecoration` yang sama berkali-kali.
class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.helperText,
    this.validator,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? helperText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        helperMaxLines: 2,
        prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
        border: const OutlineInputBorder(),
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}
