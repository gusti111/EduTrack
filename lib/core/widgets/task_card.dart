import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../models/task_model.dart';
import '../../models/task_priority.dart';
import '../../models/task_status.dart';
import '../../models/task_subject.dart';
import '../extensions/date_time_extension.dart';

/// Kartu tugas sesuai desain Figma: checkbox, avatar ikon per mata kuliah,
/// judul + mata kuliah + tenggat, lalu badge prioritas & status di kanan.
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
    final isCompleted = task.status == TaskStatus.completed;
    final status = task.effectiveStatus;
    final visual = TaskSubjectVisual.of(task.subject);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.dividerOf(context)),
      ),
      color: AppColors.surfaceOf(context),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: isCompleted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: onCheck == null ? null : (_) => onCheck!(),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(visual.icon, color: visual.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted
                                ? AppColors.textSecondaryOf(context)
                                : AppColors.textPrimaryOf(context),
                          ),
                    ),
                    if (task.subject.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.subject,
                        style: TextStyle(
                          color: visual.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 13, color: AppColors.textSecondaryOf(context)),
                        const SizedBox(width: 4),
                        Text(
                          '${task.dueDate.toDisplayDate} • ${task.dueDate.toDisplayTime}',
                          style: TextStyle(
                            color: AppColors.textSecondaryOf(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Badge(label: task.priority.label, color: task.priority.color),
                  const SizedBox(height: 6),
                  _Badge(label: status.label, color: status.color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
