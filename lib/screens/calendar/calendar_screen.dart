import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/extensions/date_time_extension.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/task_card.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';

/// Grid kalender bulanan interaktif (swipe antar bulan, tap tanggal) pakai
/// `table_calendar`. Data tetap dari `TaskProvider` — layar ini hanya
/// menambah lapisan tampilan di atasnya.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  /// Membandingkan dua DateTime dengan mengabaikan jam/menit/detik.
  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Memfilter daftar tugas berdasarkan tanggal tenggat.
  List<TaskModel> _getTasksForDay(List<TaskModel> allTasks, DateTime day) {
    return allTasks.where((task) => _isSameDay(task.dueDate, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final allTasks = provider.tasks;

    if (allTasks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kalender')),
        body: const EmptyState(
          message: 'Belum ada tugas terjadwal.',
          icon: Icons.calendar_today_outlined,
        ),
      );
    }

    final selectedTasks =
        _selectedDay == null ? <TaskModel>[] : _getTasksForDay(allTasks, _selectedDay!);

    return Scaffold(
      appBar: AppBar(title: const Text('Kalender')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: TableCalendar<TaskModel>(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
              eventLoader: (day) => _getTasksForDay(allTasks, day),
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
              ),
              onDaySelected: (selectedDay, focusedDay) {
                if (!_isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() => _calendarFormat = format);
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDay == null
                      ? 'Pilih Tanggal'
                      : 'Tenggat: ${_selectedDay!.toDisplayDate}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${selectedTasks.length} Tugas',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: selectedTasks.isEmpty
                ? const EmptyState(
                    message: 'Tidak ada tenggat tugas pada tanggal ini.',
                    icon: Icons.event_available,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: selectedTasks.length,
                    itemBuilder: (context, index) {
                      return TaskCard(task: selectedTasks[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
