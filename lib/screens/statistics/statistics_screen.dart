import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/statistic_card.dart';
import '../../models/task_priority.dart';
import '../../models/task_status.dart';
import '../../providers/task_provider.dart';

/// Statistik dibuat pakai progress bar manual (LinearProgressIndicator)
/// biar tidak nambah dependency chart eksternal. Kalau nanti mau tampilan
/// lebih kaya, tinggal ganti isi `_StatusBreakdown`/`_PriorityBreakdown`
/// dengan package seperti fl_chart — struktur data (`provider.tasksByStatus`)
/// sudah siap dipakai.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    if (provider.tasks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistik')),
        body: const EmptyState(
          message: 'Belum ada data untuk ditampilkan.',
          icon: Icons.bar_chart_outlined,
        ),
      );
    }

    final totalTasks = provider.tasks.length;
    final completedTasks = provider.tasksByStatus(TaskStatus.completed).length;
    final inProgressTasks =
        provider.tasksByStatus(TaskStatus.inProgress).length;
    final completionRate =
        ((completedTasks / totalTasks) * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ringkasan utama: tingkat penyelesaian tugas.
          Row(
            children: [
              Expanded(
                child: StatisticCard(
                  title: 'Selesai',
                  value: '$completedTasks / $totalTasks',
                  subtitle: '$completionRate% tingkat penyelesaian',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatisticCard(
                  title: 'Sedang Dikerjakan',
                  value: '$inProgressTasks',
                  subtitle: 'Tugas aktif',
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Berdasarkan Status',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final status in TaskStatus.values)
            _BreakdownRow(
              label: status.label,
              color: status.color,
              count: provider.tasksByStatus(status).length,
              total: totalTasks,
            ),
          const SizedBox(height: 24),
          Text('Berdasarkan Prioritas',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final priority in TaskPriority.values)
            _BreakdownRow(
              label: priority.label,
              color: priority.color,
              count: provider.tasks.where((t) => t.priority == priority).length,
              total: totalTasks,
            ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.color,
    required this.count,
    required this.total,
  });

  final String label;
  final Color color;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : count / total;
    final percentage = (ratio * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('$count ($percentage%)',
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
