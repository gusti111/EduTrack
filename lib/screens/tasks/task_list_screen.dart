import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/task_card.dart';
import '../../models/task_model.dart';
import '../../models/task_status.dart';
import '../../providers/task_provider.dart';
import 'add_edit_task_screen.dart';
import 'task_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Tugas Saya')),
      body: _buildBody(provider),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddEditTaskScreen(uid: widget.uid)),
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

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: provider.tasks.length,
      itemBuilder: (context, index) {
        final task = provider.tasks[index];
        return TaskCard(
          task: task,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
          ),
          onCheck: () => _toggleComplete(task),
        );
      },
    );
  }

  void _toggleComplete(TaskModel task) {
    final newStatus = task.status == TaskStatus.completed
        ? TaskStatus.pending
        : TaskStatus.completed;
    context.read<TaskProvider>().updateTask(task.copyWith(status: newStatus));
  }
}
