import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../core/errors/failure.dart';
import '../../core/extensions/date_time_extension.dart';
import '../../models/task_model.dart';
import '../../models/task_priority.dart';
import '../../models/task_status.dart';
import '../../models/task_subject.dart';
import '../../providers/task_provider.dart';

class AddEditTaskScreen extends StatefulWidget {
  const AddEditTaskScreen({
    super.key,
    required this.uid,
    this.existingTask,
    this.initialDate,
  });

  final String uid;

  /// Kalau null -> mode tambah. Kalau diisi -> mode edit.
  final TaskModel? existingTask;

  /// Tanggal awal untuk field Deadline saat mode tambah, dipakai
  /// CalendarScreen supaya tugas baru langsung terisi tanggal yang sedang
  /// dipilih user di kalender. Diabaikan kalau [existingTask] tidak null.
  final DateTime? initialDate;

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  static const _otherSubject = 'Lainnya';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _customSubjectController;
  String? _subject;
  late DateTime _dueDate;
  late TaskPriority _priority;
  late TaskStatus _status;
  bool _isSaving = false;

  bool get _isEditMode => widget.existingTask != null;

  /// True kalau dropdown lagi di posisi "Lainnya" — di sinilah kolom teks
  /// bebas untuk mata kuliah custom ditampilkan.
  bool get _isCustomSubject => _subject == _otherSubject;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    final savedSubject =
        (task != null && task.subject.isNotEmpty) ? task.subject : null;
    // Kalau mata kuliah tersimpan tidak ada di daftar pilihan cepat
    // (TaskSubjects.options), berarti itu hasil ketik manual sebelumnya —
    // tampilkan dropdown di posisi "Lainnya" dan isi teksnya ke kolom
    // custom, bukan menghilang begitu saja.
    final isKnownSubject =
        savedSubject != null && TaskSubjects.options.contains(savedSubject);

    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _customSubjectController = TextEditingController(
      text: (savedSubject != null && !isKnownSubject) ? savedSubject : '',
    );
    _subject = savedSubject == null
        ? null
        : (isKnownSubject ? savedSubject : _otherSubject);
    _dueDate = task?.dueDate ??
        widget.initialDate ??
        DateTime.now().add(const Duration(days: 1));
    _priority = task?.priority ?? TaskPriority.high;
    // Overdue bukan pilihan manual di form — kalau tugas lama sudah lewat
    // deadline, tetap tampilkan status tersimpan aslinya (bukan Tertunda).
    _status = task?.status ?? TaskStatus.pending;
    _descController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _customSubjectController.dispose();
    super.dispose();
  }

  /// Mata kuliah final yang disimpan ke [TaskModel]: teks custom kalau
  /// dropdown di posisi "Lainnya", atau nilai dropdown biasa.
  String get _resolvedSubject =>
      _isCustomSubject ? _customSubjectController.text.trim() : (_subject ?? '');

  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );
    if (pickedTime == null) return;

    setState(() {
      _dueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<TaskProvider>();
    final task = TaskModel(
      id: widget.existingTask?.id ?? '',
      uid: widget.uid,
      title: _titleController.text.trim(),
      subject: _resolvedSubject,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      status: _status,
      createdAt: widget.existingTask?.createdAt ?? DateTime.now(),
    );

    final success = _isEditMode
        ? await provider.updateTask(task)
        : await provider.addTask(task);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      if (provider.failure is PendingSyncFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.failure!.message)),
        );
      }
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(provider.failure?.message ?? 'Gagal menyimpan tugas')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Tugas' : 'Tambah Tugas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLightOf(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.edit_note, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Isi detail tugas dengan lengkap agar lebih mudah '
                        'dikelola dan tidak terlewat.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _FieldLabel('Judul Tugas'),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan Judul Tugas',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Judul tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Mata Kuliah'),
              DropdownButtonFormField<String>(
                initialValue: _subject,
                decoration: const InputDecoration(
                  hintText: 'Pilih Mata Kuliah',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
                items: TaskSubjects.options
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => _subject = value),
                validator: (value) =>
                    value == null ? 'Pilih mata kuliah dulu' : null,
              ),
              // Muncul cuma kalau dropdown di posisi "Lainnya" — user
              // ketik sendiri nama mata kuliahnya.
              if (_isCustomSubject) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customSubjectController,
                  decoration: const InputDecoration(
                    hintText: 'Tulis nama mata kuliah',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  validator: (value) {
                    if (!_isCustomSubject) return null;
                    return (value == null || value.trim().isEmpty)
                        ? 'Nama mata kuliah tidak boleh kosong'
                        : null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              const _FieldLabel('Deadline'),
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    '${_dueDate.toDisplayDate}  •  ${_dueDate.toDisplayTime}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Prioritas'),
              Row(
                children: TaskPriority.values
                    .map((p) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: p != TaskPriority.values.last ? 8 : 0,
                            ),
                            child: _ChoiceChipTile(
                              label: p.label,
                              icon: Icons.flag,
                              color: p.color,
                              selected: _priority == p,
                              onTap: () => setState(() => _priority = p),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Status'),
              Row(
                children: [
                  TaskStatus.pending,
                  TaskStatus.inProgress,
                  TaskStatus.completed,
                ].map((s) {
                  final icon = switch (s) {
                    TaskStatus.pending => Icons.radio_button_unchecked,
                    TaskStatus.inProgress => Icons.autorenew,
                    TaskStatus.completed => Icons.check_circle_outline,
                    TaskStatus.overdue => Icons.error_outline,
                  };
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: s != TaskStatus.completed ? 8 : 0,
                      ),
                      child: _ChoiceChipTile(
                        label: s.label,
                        icon: icon,
                        color: s.color,
                        selected: _status == s,
                        onTap: () => setState(() => _status = s),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Deskripsi (Opsional)'),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  hintText: 'Jelaskan detail tugas, catatan penting, '
                      'atau hal yang perlu diperhatikan...',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Tugas'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Chip pilihan bergaya "outline aktif" seperti pada desain Figma untuk
/// Prioritas & Status: border + teks berwarna saat dipilih, abu-abu saat
/// tidak.
class _ChoiceChipTile extends StatelessWidget {
  const _ChoiceChipTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected ? color.withValues(alpha: 0.10) : AppColors.surfaceOf(context),
          border: Border.all(
            color: selected ? color : AppColors.dividerOf(context),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? color : AppColors.textSecondaryOf(context)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.textSecondaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
