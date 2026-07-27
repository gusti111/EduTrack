import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../core/errors/failure.dart';
import '../../core/extensions/date_time_extension.dart';
import '../../core/utils/validator.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';

/// Edit Profil versi lengkap, mengikuti struktur desain Figma (Informasi
/// Pribadi / Informasi Kontak) ditambah satu section baru "Informasi
/// Akademik" untuk status (Mahasiswa/Pelajar/Umum) dan semester — sesuai
/// permintaan supaya profil punya data yang lebih kaya, bukan cuma nama.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.uid,
    required this.email,
    this.profile,
  });

  final String uid;
  final String email;

  /// Profil yang sudah ada (kalau ada). Null berarti dokumen profil belum
  /// pernah ditulis lengkap — semua field tambahan mulai dari kosong.
  final UserModel? profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  DateTime? _birthDate;
  String? _gender;
  String _status = UserStatus.mahasiswa;
  int? _semester;
  bool _isSaving = false;

  bool get _isMahasiswa => _status == UserStatus.mahasiswa;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController = TextEditingController(text: profile?.displayName ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _addressController = TextEditingController(text: profile?.address ?? '');
    _birthDate = profile?.birthDate;
    _gender = profile?.gender;
    _status = profile?.status ?? UserStatus.mahasiswa;
    _semester = profile?.semester;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Pilih Tanggal Lahir',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final fields = <String, dynamic>{
      'displayName': _nameController.text.trim(),
      'gender': _gender,
      'birthDate': _birthDate?.toIso8601String(),
      'status': _status,
      // Semester eksplisit di-null-kan kalau status bukan Mahasiswa, supaya
      // tidak ada data semester "nyangkut" di Firestore untuk status lain.
      'semester': _isMahasiswa ? _semester : null,
      'phone': _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      'address': _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
    };

    try {
      await context.read<AuthRepository>().updateProfileFields(widget.uid, fields);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      if (e is PendingSyncFailure) {
        // Offline-first: perubahan sudah tersimpan di local cache dan akan
        // tersinkron otomatis saat koneksi kembali — tetap dianggap sukses.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
        Navigator.pop(context, true);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan perubahan')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Edit Profil'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primaryLightOf(context),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionCard(
              icon: Icons.person_outline,
              title: 'Informasi Pribadi',
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: 'Nama Lengkap',
                  icon: Icons.person_outline,
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),
                _ReadOnlyField(label: 'Email', value: widget.email, icon: Icons.email_outlined),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _PickerField(
                        label: 'Tanggal Lahir',
                        icon: Icons.calendar_today_outlined,
                        value: _birthDate?.toDisplayDate ?? 'Pilih tanggal',
                        onTap: _pickBirthDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DropdownField<String>(
                        label: 'Jenis Kelamin',
                        icon: Icons.wc_outlined,
                        value: _gender,
                        hint: 'Pilih',
                        items: UserGender.options,
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.school_outlined,
              title: 'Informasi Akademik',
              children: [
                _DropdownField<String>(
                  label: 'Status',
                  icon: Icons.badge_outlined,
                  value: _status,
                  items: UserStatus.options,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _status = v;
                      if (v != UserStatus.mahasiswa) _semester = null;
                    });
                  },
                ),
                if (_isMahasiswa) ...[
                  const SizedBox(height: 16),
                  _DropdownField<int>(
                    label: 'Semester',
                    icon: Icons.numbers_outlined,
                    value: _semester,
                    hint: 'Pilih semester',
                    items: List.generate(14, (i) => i + 1),
                    itemLabel: (v) => 'Semester $v',
                    onChanged: (v) => setState(() => _semester = v),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.call_outlined,
              title: 'Informasi Kontak',
              children: [
                CustomTextField(
                  controller: _phoneController,
                  label: 'Nomor Telepon',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _addressController,
                  label: 'Alamat',
                  icon: Icons.location_on_outlined,
                ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: AppColors.bg(context),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        child: Text(value, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.itemLabel,
  });

  final String label;
  final IconData icon;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final String Function(T)? itemLabel;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      hint: hint != null ? Text(hint!) : null,
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(itemLabel != null ? itemLabel!(e) : e.toString()),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
