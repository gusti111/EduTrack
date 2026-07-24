import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/date_time_extension.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/task_status.dart';
import '../../providers/notification_provider.dart';
import '../../providers/task_provider.dart';
import '../notification/notification_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EduTrack'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NotificationScreen(uid: uid)),
            ),
          ),
        ],
      ),
      body: provider.isLoading && provider.tasks.isEmpty
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: () async => provider.listenToTasks(uid),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatsRow(provider: provider),
                  const SizedBox(height: 24),
                  Text('Tugas Mendatang',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _UpcomingTasks(provider: provider),
                ],
              ),
            ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.provider});

  final TaskProvider provider;

  @override
  Widget build(BuildContext context) {
    final total = provider.tasks.length;
    final completed = provider.tasksByStatus(TaskStatus.completed).length;
    final overdue = provider.tasks
        .where((t) => t.status != TaskStatus.completed && t.dueDate.isPastNow)
        .length;

    return Row(
      children: [
        Expanded(
            child:
                _StatCard(label: 'Total', value: total, color: Colors.indigo)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                label: 'Selesai', value: completed, color: Colors.green)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                label: 'Terlambat', value: overdue, color: Colors.red)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      // ignore: deprecated_member_use
      color: color.withOpacity(0.1),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _UpcomingTasks extends StatelessWidget {
  const _UpcomingTasks({required this.provider});

  final TaskProvider provider;

  @override
  Widget build(BuildContext context) {
    final upcoming = provider.tasks
        .where((t) => t.status != TaskStatus.completed)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (upcoming.isEmpty) {
      return const EmptyState(
          message: 'Tidak ada tugas mendatang. Kerja bagus!',
          icon: Icons.celebration_outlined);
    }

    return Column(
      children: upcoming.take(5).map((task) {
        final isOverdue = task.dueDate.isPastNow;
        return Card(
          child: ListTile(
            title: Text(task.title),
            subtitle: Text(task.dueDate.toDisplayDate),
            trailing: Icon(
              isOverdue ? Icons.warning_amber_rounded : Icons.schedule,
              color: isOverdue ? Colors.red : Colors.grey,
            ),
          ),
        );
      }).toList(),
    );
  }
}
