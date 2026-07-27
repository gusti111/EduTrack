import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/date_time_extension.dart';
import '../../models/task_model.dart';
import '../../models/task_priority.dart';
import '../../models/task_status.dart';
import '../../providers/task_provider.dart';
import 'add_edit_task_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.task});

  final TaskModel task;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: Text('Yakin ingin menghapus "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await context.read<TaskProvider>().deleteTask(task.id);
    if (!context.mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus tugas')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AddEditTaskScreen(
                      uid: task.uid,
                      existingTask: task,
                      initialDate: task.dueDate,
                    ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Tenggat: ${task.dueDate.toDisplayDate}'),
            const SizedBox(height: 4),
            Text('Prioritas: ${task.priority.label}'),
            const SizedBox(height: 4),
            Text('Status: ${task.status.label}'),
            if (task.description != null) ...[
              const SizedBox(height: 16),
              Text(task.description!),
            ],
          ],
        ),
      ),
    );
  }
}
