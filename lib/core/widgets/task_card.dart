import 'package:edutrack/models/task_priority.dart';
import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../models/task_status.dart';
import '../extensions/date_time_extension.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onCheck,
  });

  final TaskModel task;
  final VoidCallback? onTap;
  final VoidCallback? onCheck;

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        task.status != TaskStatus.completed && task.dueDate.isPastNow;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: task.status == TaskStatus.completed,
          onChanged: onCheck == null ? null : (_) => onCheck!(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.status == TaskStatus.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Text(
          'Tenggat: ${task.dueDate.toDisplayDate}'
          '${isOverdue ? ' • Terlambat' : ''}',
          style: TextStyle(color: isOverdue ? Colors.red : null),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: task.priority.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            task.priority.label,
            style: TextStyle(
              color: task.priority.color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
