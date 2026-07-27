import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/task_card.dart';
import '../../models/task_model.dart';
import '../../models/task_priority.dart';
import '../../models/task_status.dart';
import '../../providers/task_provider.dart';
import 'add_edit_task_screen.dart';
import 'task_detail_screen.dart';

/// Filter status yang tersedia di chip atas. Berbeda dari [TaskStatus] murni
/// karena "Belum Selesai" di sini sengaja menggabungkan
/// pending/inProgress/overdue — dari sudut pandang user, ketiganya sama-sama
/// "belum kelar", hanya "Selesai" yang benar-benar sudah tuntas.
enum _StatusFilter { all, notDone, done }

extension on _StatusFilter {
  String get label => switch (this) {
        _StatusFilter.all => 'Semua',
        _StatusFilter.notDone => 'Belum Selesai',
        _StatusFilter.done => 'Selesai',
      };

  bool matches(TaskModel task) => switch (this) {
        _StatusFilter.all => true,
        _StatusFilter.done => task.effectiveStatus == TaskStatus.completed,
        _StatusFilter.notDone => task.effectiveStatus != TaskStatus.completed,
      };
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key, required this.uid});

  /// uid user yang sedang login. Di aplikasi nyata ini datang dari
  /// AuthProvider — di-inject langsung di sini biar slice ini bisa
  /// dijalankan/di-review berdiri sendiri.
  final String uid;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  // Catatan: TaskListScreen TIDAK memanggil listenToTasks() di initState.
  // HomeShell sudah melakukannya sekali untuk seluruh tab (lihat
  // home_shell.dart) karena semua tab dibangun bersamaan di dalam
  // IndexedStack. Memanggilnya lagi di sini dulu menyebabkan subscription
  // Firestore dibatalkan & dibuat ulang dua kali setiap kali HomeShell
  // mount, memicu flicker loading yang tidak perlu.

  final _searchController = TextEditingController();
  String _query = '';
  _StatusFilter _statusFilter = _StatusFilter.all;
  TaskPriority? _priorityFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(TaskModel task) {
    final matchesQuery = _query.isEmpty ||
        task.title.toLowerCase().contains(_query) ||
        task.subject.toLowerCase().contains(_query);
    final matchesStatus = _statusFilter.matches(task);
    final matchesPriority =
        _priorityFilter == null || task.priority == _priorityFilter;
    return matchesQuery && matchesStatus && matchesPriority;
  }

  Future<void> _openPriorityFilter() async {
    final picked = await showModalBottomSheet<Object?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  'Filter Prioritas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                leading: Icon(Icons.all_inclusive, color: AppColors.textSecondaryOf(context)),
                title: const Text('Semua Prioritas'),
                trailing: _priorityFilter == null
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, const _ClearPriority()),
              ),
              for (final p in TaskPriority.values)
                ListTile(
                  leading: Icon(Icons.flag, color: p.color),
                  title: Text(p.label),
                  trailing: _priorityFilter == p
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, p),
                ),
            ],
          ),
        ),
      ),
    );

    if (picked is _ClearPriority) {
      setState(() => _priorityFilter = null);
    } else if (picked is TaskPriority) {
      setState(() => _priorityFilter = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(title: const Text('Tugas')),
      body: _buildBody(provider),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditTaskScreen(
              uid: widget.uid,
              initialDate: DateTime.now(),
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(TaskProvider provider) {
    if (provider.isLoading && provider.tasks.isEmpty) {
      return const LoadingWidget();
    }
    if (provider.failure != null && provider.tasks.isEmpty) {
      return ErrorState(
        failure: provider.failure!,
        onRetry: () => provider.listenToTasks(widget.uid),
      );
    }
    if (provider.tasks.isEmpty) {
      return const EmptyState(
        message: 'Belum ada tugas.\nTekan tombol + untuk menambahkan.',
        icon: Icons.task_alt,
      );
    }

    final filtered = provider.tasks.where(_matches).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari tugas, mata pelajaran ...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.surfaceOf(context),
              suffixIcon: IconButton(
                icon: const Icon(Icons.tune, color: AppColors.primary),
                tooltip: 'Filter prioritas',
                onPressed: _openPriorityFilter,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.dividerOf(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.dividerOf(context)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final filter in _StatusFilter.values) ...[
                _FilterChip(
                  label: filter.label,
                  selected: _statusFilter == filter,
                  onTap: () => setState(() => _statusFilter = filter),
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              if (_priorityFilter != null)
                InputChip(
                  label: Text(_priorityFilter!.label),
                  labelStyle: TextStyle(
                    color: _priorityFilter!.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  backgroundColor: _priorityFilter!.color.withValues(alpha: 0.12),
                  side: BorderSide.none,
                  onDeleted: () => setState(() => _priorityFilter = null),
                  deleteIcon: Icon(Icons.close, size: 15, color: _priorityFilter!.color),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _statusFilter == _StatusFilter.all ? 'Semua tugas' : _statusFilter.label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                '${filtered.length} Tugas',
                style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12.5),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  message: 'Tidak ada tugas yang cocok dengan filter ini.',
                  icon: Icons.search_off,
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 90),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final task = filtered[index];
                    return TaskCard(
                      task: task,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
                      ),
                      onCheck: () => _toggleComplete(task),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _toggleComplete(TaskModel task) {
    final newStatus = task.status == TaskStatus.completed
        ? TaskStatus.pending
        : TaskStatus.completed;
    context.read<TaskProvider>().updateTask(task.copyWith(status: newStatus));
  }
}

/// Sentinel supaya bottom sheet filter prioritas bisa membedakan "user pilih
/// Semua Prioritas" (harus mengosongkan filter) dari "user menutup sheet
/// tanpa memilih apa-apa" (biarkan filter lama).
class _ClearPriority {
  const _ClearPriority();
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.dividerOf(context)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondaryOf(context),
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
