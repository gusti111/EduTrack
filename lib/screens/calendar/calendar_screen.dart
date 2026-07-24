import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/date_time_extension.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/task_card.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';

/// Versi dasar: task dikelompokkan per tanggal tenggat, ditampilkan sebagai
/// daftar section. Ini BUKAN pengganti kalender grid interaktif — kalau mau
/// tampilan grid bulan penuh (swipe antar bulan, tap tanggal), pertimbangkan
/// package `table_calendar` dan pasang di sini sebagai lapisan tampilan saja
/// (data tetap dari `TaskProvider`, tidak perlu ubah lapisan lain).
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    if (provider.tasks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kalender')),
        body: const EmptyState(message: 'Belum ada tugas terjadwal.', icon: Icons.calendar_today_outlined),
      );
    }

    final grouped = <String, List<TaskModel>>{};
    for (final task in provider.tasks) {
      final key = task.dueDate.toDisplayDate;
      grouped.putIfAbsent(key, () => []).add(task);
    }
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) =>
          grouped[a]!.first.dueDate.compareTo(grouped[b]!.first.dueDate));

    return Scaffold(
      appBar: AppBar(title: const Text('Kalender')),
      body: ListView.builder(
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final dateLabel = sortedKeys[index];
          final tasksForDate = grouped[dateLabel]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              ...tasksForDate.map((task) => TaskCard(task: task)),
            ],
          );
        },
      ),
    );
  }
}
