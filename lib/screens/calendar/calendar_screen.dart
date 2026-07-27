import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../app/theme/app_colors.dart';
import '../../core/extensions/date_time_extension.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/task_model.dart';
import '../../models/task_priority.dart';
import '../../models/task_status.dart';
import '../../models/task_subject.dart';
import '../../providers/task_provider.dart';
import '../tasks/add_edit_task_screen.dart';
import '../tasks/task_detail_screen.dart';

/// Grid kalender bulanan interaktif (swipe antar bulan, tap tanggal) pakai
/// `table_calendar`. Data tetap dari `TaskProvider` — layar ini hanya
/// menambah lapisan tampilan di atasnya. Locale 'id_ID' (nama hari/bulan)
/// diinisialisasi sekali di bootstrap.dart sebelum runApp, jadi aman
/// dipakai langsung di sini.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.uid});

  final String uid;

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
    return allTasks.where((task) => _isSameDay(task.dueDate, day)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final allTasks = provider.tasks;
    final selectedDay = _selectedDay ?? _focusedDay;
    final selectedTasks = _getTasksForDay(allTasks, selectedDay);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Kalender'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_outlined),
            tooltip: 'Ke hari ini',
            onPressed: _goToToday,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditTaskScreen(
              uid: widget.uid,
              initialDate: DateTime(
                selectedDay.year,
                selectedDay.month,
                selectedDay.day,
                9,
              ),
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.dividerOf(context)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TableCalendar<TaskModel>(
                locale: 'id_ID',
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
                eventLoader: (day) => _getTasksForDay(allTasks, day),
                startingDayOfWeek: StartingDayOfWeek.monday,
                daysOfWeekHeight: 28,
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  weekendStyle: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: true,
                  defaultTextStyle: TextStyle(color: AppColors.textPrimaryOf(context)),
                  weekendTextStyle: TextStyle(color: AppColors.textPrimaryOf(context)),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primaryLightOf(context),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimaryOf(context),
                  ),
                  leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.primary),
                  rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.primary),
                ),
                calendarBuilders: CalendarBuilders(
                  // Titik-titik warna sesuai mata kuliah tiap tugas di
                  // tanggal itu (maksimal 3 dot) — menggantikan marker
                  // default table_calendar yang cuma satu warna.
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    final colors = events
                        .take(3)
                        .map((e) => TaskSubjectVisual.of(e.subject).color)
                        .toList();
                    return Positioned(
                      bottom: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final color in colors)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration:
                                  BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                    );
                  },
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
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(color: AppColors.textPrimaryOf(context)),
                      children: [
                        const TextSpan(
                          text: 'Agenda  •  ',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                        ),
                        TextSpan(
                          text: selectedDay.toDisplayDateLong,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  '${selectedTasks.length} Agenda',
                  style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12.5),
                ),
              ],
            ),
          ),
          Expanded(
            child: selectedTasks.isEmpty
                ? const EmptyState(
                    message: 'Tidak ada agenda lagi.\nNikmati waktu luangmu!',
                    icon: Icons.event_available,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                    itemCount: selectedTasks.length,
                    itemBuilder: (context, index) {
                      final task = selectedTasks[index];
                      return _AgendaTile(
                        task: task,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Kartu agenda per tugas: ikon bulat sesuai mata kuliah, judul + mata
/// kuliah, jam tenggat, dan badge prioritas — mengikuti gaya daftar Agenda
/// pada desain Figma.
class _AgendaTile extends StatelessWidget {
  const _AgendaTile({required this.task, this.onTap});

  final TaskModel task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visual = TaskSubjectVisual.of(task.subject);
    final status = task.effectiveStatus;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
              Container(
                width: 42,
                height: 42,
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
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    if (task.subject.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.subject,
                        style: TextStyle(
                          color: visual.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 13, color: AppColors.textSecondaryOf(context)),
                        const SizedBox(width: 4),
                        Text(
                          'Pukul ${task.dueDate.toDisplayTime}',
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
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}
