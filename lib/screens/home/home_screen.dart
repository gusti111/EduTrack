import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../core/extensions/date_time_extension.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/task_model.dart';
import '../../models/task_priority.dart';
import '../../models/task_status.dart';
import '../../models/task_subject.dart';
import '../../models/user_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/task_provider.dart';
import '../../repositories/auth_repository.dart';
import '../notification/notification_screen.dart';
import '../tasks/add_edit_task_screen.dart';
import '../tasks/task_detail_screen.dart';

/// Beranda, dirombak mengikuti desain Figma: sapaan personal, pencarian,
/// ringkasan 4 kartu, daftar tugas hari ini, tugas mendatang (horizontal),
/// dan progress mingguan.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.uid});

  final String uid;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  Future<UserModel?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = context.read<AuthRepository>().getUserProfile(widget.uid);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(TaskModel task) {
    if (_query.isEmpty) return true;
    return task.title.toLowerCase().contains(_query) ||
        task.subject.toLowerCase().contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
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
      body: provider.isLoading && provider.tasks.isEmpty
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: () async => provider.listenToTasks(widget.uid),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                children: [
                  FutureBuilder<UserModel?>(
                    future: _profileFuture,
                    builder: (context, snapshot) {
                      final profile = snapshot.data;
                      final name = profile?.displayName?.split(' ').first ??
                          'Sahabat Belajar';
                      final initial =
                          (profile?.displayName?.isNotEmpty ?? false)
                              ? profile!.displayName![0].toUpperCase()
                              : '?';
                      return _Header(
                        name: name,
                        initial: initial,
                        unreadCount: unreadCount,
                        onNotificationTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationScreen(uid: widget.uid),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari tugas, mata pelajaran ...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.surfaceOf(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: AppColors.dividerOf(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: AppColors.dividerOf(context)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ringkasan',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _SummaryRow(provider: provider),
                  const SizedBox(height: 24),
                  Text('Tugas Hari Ini',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                  const SizedBox(height: 10),
                  _TodayTasks(provider: provider, matchesQuery: _matchesQuery),
                  const SizedBox(height: 24),
                  Text('Tugas Mendatang',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                  const SizedBox(height: 10),
                  _UpcomingTasks(
                      provider: provider, matchesQuery: _matchesQuery),
                  const SizedBox(height: 24),
                  _WeeklyProgress(provider: provider),
                ],
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.initial,
    required this.unreadCount,
    required this.onNotificationTap,
  });

  final String name;
  final String initial;
  final int unreadCount;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hai, $name! 👋',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Semangat belajar hari ini!',
                style: TextStyle(color: AppColors.textSecondaryOf(context)),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onNotificationTap,
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
        const SizedBox(width: 4),
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primaryLightOf(context),
          child: Text(
            initial,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.provider});

  final TaskProvider provider;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final total = provider.tasks.length;
    final completed = provider.tasksByStatus(TaskStatus.completed).length;
    final overdue = provider.tasksByStatus(TaskStatus.overdue).length;
    final dueToday = provider.tasks
        .where((t) =>
            t.effectiveStatus != TaskStatus.completed &&
            t.dueDate.year == now.year &&
            t.dueDate.month == now.month &&
            t.dueDate.day == now.day)
        .length;

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.8,
      children: [
        _SummaryCard(
            icon: Icons.assignment_outlined,
            value: total,
            label: 'Total tugas',
            color: AppColors.primary),
        _SummaryCard(
            icon: Icons.check_circle,
            value: completed,
            label: 'Selesai',
            color: AppColors.success),
        _SummaryCard(
            icon: Icons.error,
            value: overdue,
            label: 'Tertunda',
            color: AppColors.danger),
        _SummaryCard(
            icon: Icons.today,
            value: dueToday,
            label: 'Deadline hari ini',
            color: AppColors.warning),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  final IconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text('$value',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
                fontSize: 9.5, color: AppColors.textSecondaryOf(context)),
          ),
        ],
      ),
    );
  }
}

class _TodayTasks extends StatelessWidget {
  const _TodayTasks({required this.provider, required this.matchesQuery});

  final TaskProvider provider;
  final bool Function(TaskModel) matchesQuery;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = provider.tasks
        .where((t) =>
            t.dueDate.year == now.year &&
            t.dueDate.month == now.month &&
            t.dueDate.day == now.day &&
            matchesQuery(t))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (today.isEmpty) {
      return const EmptyState(
        message: 'Tidak ada tugas untuk hari ini. Nikmati waktu luangmu!',
        icon: Icons.celebration_outlined,
      );
    }

    return Column(
      children: today.map((task) {
        final visual = TaskSubjectVisual.of(task.subject);
        final isCompleted = task.status == TaskStatus.completed;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.dividerOf(context)),
          ),
          child: ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: visual.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(visual.icon, color: visual.color, size: 20),
            ),
            title: Text(
              task.subject.isNotEmpty ? task.subject : task.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${task.title}\n${task.dueDate.toDisplayTime}'),
            isThreeLine: true,
            trailing: IconButton(
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted
                    ? AppColors.success
                    : AppColors.textSecondaryOf(context),
              ),
              onPressed: () {
                final newStatus =
                    isCompleted ? TaskStatus.pending : TaskStatus.completed;
                context
                    .read<TaskProvider>()
                    .updateTask(task.copyWith(status: newStatus));
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _UpcomingTasks extends StatelessWidget {
  const _UpcomingTasks({required this.provider, required this.matchesQuery});

  final TaskProvider provider;
  final bool Function(TaskModel) matchesQuery;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = provider.tasks
        .where((t) =>
            t.effectiveStatus != TaskStatus.completed &&
            t.dueDate
                .isAfter(today.add(const Duration(hours: 23, minutes: 59))) &&
            matchesQuery(t))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (upcoming.isEmpty) {
      return const EmptyState(
        message: 'Belum ada tugas mendatang.',
        icon: Icons.event_available_outlined,
      );
    }

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: upcoming.take(8).length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final task = upcoming[index];
          TaskSubjectVisual.of(task.subject);
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
            ),
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.dividerOf(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${task.dueDate.day}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _monthAbbr(task.dueDate.month),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.subject.isNotEmpty ? task.subject : 'Umum',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondaryOf(context)),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: task.priority.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.priority.label,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: task.priority.color),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _monthAbbr(int month) {
    const names = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MEI',
      'JUN',
      'JUL',
      'AGU',
      'SEP',
      'OKT',
      'NOV',
      'DES',
    ];
    return names[month - 1];
  }
}

class _WeeklyProgress extends StatelessWidget {
  const _WeeklyProgress({required this.provider});

  final TaskProvider provider;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final weekTasks = provider.tasks
        .where((t) =>
            t.dueDate.isAfter(startOfWeek) && t.dueDate.isBefore(endOfWeek))
        .toList();
    final weekCompleted =
        weekTasks.where((t) => t.status == TaskStatus.completed).length;
    final percent = weekTasks.isEmpty ? 0.0 : weekCompleted / weekTasks.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progress Mingguan',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text(
                '${(percent * 100).round()}%',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: AppColors.primaryLightOf(context),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            weekTasks.isEmpty
                ? 'Belum ada tugas dengan tenggat minggu ini.'
                : 'Kamu telah menyelesaikan $weekCompleted dari ${weekTasks.length} tugas minggu ini',
            style: TextStyle(
                color: AppColors.textSecondaryOf(context), fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
