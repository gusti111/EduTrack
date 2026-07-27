import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../core/extensions/date_time_extension.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/task_category.dart';
import '../../models/task_model.dart';
import '../../models/task_status.dart';
import '../../providers/task_provider.dart';

/// Rentang waktu yang mempengaruhi 4 kartu ringkasan & kartu progres —
/// bar mingguan & donut kategori tetap tampil apa adanya (tidak ikut
/// terpotong periode) supaya selalu ada gambaran pola belajar, walau
/// user sedang melihat filter "Bulanan".
enum _Period { summary, weekly, monthly }

extension on _Period {
  String get label => switch (this) {
        _Period.summary => 'Ringkasan',
        _Period.weekly => 'Mingguan',
        _Period.monthly => 'Bulanan',
      };
}

/// Statistik dibangun tanpa dependency chart eksternal (fl_chart dsb) —
/// bar chart & donut chart di bawah ini murni `CustomPainter`/widget Flutter
/// biasa, supaya tidak menambah beban `pubspec.yaml`.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  _Period _period = _Period.summary;

  bool _inPeriod(TaskModel task, DateTime now) {
    switch (_period) {
      case _Period.summary:
        return true;
      case _Period.weekly:
        final start = now.startOfWeek;
        final end = start.add(const Duration(days: 7));
        return !task.dueDate.isBefore(start) && task.dueDate.isBefore(end);
      case _Period.monthly:
        return task.dueDate.year == now.year && task.dueDate.month == now.month;
    }
  }

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

    final now = DateTime.now();
    final scopedTasks = provider.tasks.where((t) => _inPeriod(t, now)).toList();

    final total = scopedTasks.length;
    final completed =
        scopedTasks.where((t) => t.effectiveStatus == TaskStatus.completed).length;
    final inProgress =
        scopedTasks.where((t) => t.effectiveStatus == TaskStatus.inProgress).length;
    final overdue =
        scopedTasks.where((t) => t.effectiveStatus == TaskStatus.overdue).length;
    final completionRate = total == 0 ? 0.0 : completed / total;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Statistik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Lihat kalender',
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          Row(
            children: [
              for (final p in _Period.values) ...[
                Expanded(
                  child: _PeriodTab(
                    label: p.label,
                    selected: _period == p,
                    onTap: () => setState(() => _period = p),
                  ),
                ),
                if (p != _Period.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.8,
            children: [
              _SummaryTile(
                icon: Icons.assignment_outlined,
                value: total,
                label: 'Total tugas',
                color: AppColors.primary,
              ),
              _SummaryTile(
                icon: Icons.check_circle,
                value: completed,
                label: 'Selesai',
                color: AppColors.success,
                percentOfTotal: total == 0 ? null : completed / total,
              ),
              _SummaryTile(
                icon: Icons.access_time_filled,
                value: inProgress,
                label: 'Sedang Dikerjakan',
                color: AppColors.warning,
                percentOfTotal: total == 0 ? null : inProgress / total,
              ),
              _SummaryTile(
                icon: Icons.error,
                value: overdue,
                label: 'Tertunda',
                color: AppColors.danger,
                percentOfTotal: total == 0 ? null : overdue / total,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ProgressCard(completed: completed, total: total, rate: completionRate),
          const SizedBox(height: 20),
          _WeeklyProductivityCard(tasks: provider.tasks, now: now),
          const SizedBox(height: 20),
          _CategoryCard(tasks: scopedTasks),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _StreakCard(tasks: provider.tasks, now: now)),
              const SizedBox(width: 12),
              Expanded(child: _MotivationCard(now: now)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.dividerOf(context)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondaryOf(context),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Kartu ringkasan 4-kolom, gaya sama seperti di HomeScreen/ProfileScreen
/// tapi ditambah baris kecil `percentOfTotal` (mis. "64% dari total").
class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.percentOfTotal,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color color;
  final double? percentOfTotal;

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
          Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(fontSize: 9.5, color: AppColors.textSecondaryOf(context)),
          ),
          if (percentOfTotal != null) ...[
            const SizedBox(height: 2),
            Text(
              '${(percentOfTotal! * 100).toStringAsFixed(0)}% dari total',
              style: TextStyle(fontSize: 8.5, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

/// Target mingguan tetap (70%) — aplikasi ini belum punya fitur
/// atur-target-sendiri, jadi angka ini cuma tolok ukur tetap seperti pada
/// desain Figma, bukan nilai yang bisa diubah user.
const _weeklyTargetRate = 0.7;

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.completed, required this.total, required this.rate});

  final int completed;
  final int total;
  final double rate;

  @override
  Widget build(BuildContext context) {
    final metTarget = rate >= _weeklyTargetRate;
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
          const Text('Progres Penyelesaian',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 13),
              children: [
                const TextSpan(text: 'Kamu sudah menyelesaikan '),
                TextSpan(
                  text: '$completed dari $total tugas',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 10,
              backgroundColor: AppColors.primaryLightOf(context),
              valueColor: AlwaysStoppedAnimation(
                metTarget ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Target: ${(_weeklyTargetRate * 100).toStringAsFixed(0)}%'
            '${metTarget ? '  •  Target tercapai! 🎉' : ''}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: metTarget ? AppColors.success : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bar chart mingguan (Sen-Min) murni Container/Row — jumlah tugas yang
/// SELESAI dengan tenggat jatuh pada tiap hari di minggu berjalan.
class _WeeklyProductivityCard extends StatelessWidget {
  const _WeeklyProductivityCard({required this.tasks, required this.now});

  final List<TaskModel> tasks;
  final DateTime now;

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final start = now.startOfWeek;
    final counts = List<int>.generate(7, (i) {
      final day = start.add(Duration(days: i));
      return tasks.where((t) {
        return t.effectiveStatus == TaskStatus.completed &&
            t.dueDate.year == day.year &&
            t.dueDate.month == day.month &&
            t.dueDate.day == day.day;
      }).length;
    });
    final maxCount = counts.fold<int>(0, math.max).clamp(1, 999);

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
          const Text('Produktivitas Mingguan',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Tugas selesai per hari, minggu ini',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryOf(context))),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${counts[i]}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 70.0 * (counts[i] / maxCount).clamp(0.04, 1.0),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLightOf(context),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: counts[i] == 0
                                ? null
                                : Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 6),
                          Text(_dayLabels[i],
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textSecondaryOf(context))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.tasks});

  final List<TaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    final counts = <TaskCategory, int>{};
    for (final task in tasks) {
      counts[task.category] = (counts[task.category] ?? 0) + 1;
    }
    final total = tasks.length;

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
          const Text('Tugas Berdasarkan Kategori',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 16),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Belum ada tugas pada periode ini.',
                  style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12.5)),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CustomPaint(
                    painter: _DonutPainter(counts: counts, total: total),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final category in TaskCategory.values)
                        if ((counts[category] ?? 0) > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                      color: category.color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(category.label,
                                      style: const TextStyle(fontSize: 12.5)),
                                ),
                                Text(
                                  '${counts[category]} tugas',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondaryOf(context)),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Menggambar donut chart manual (tanpa fl_chart): satu arc per kategori,
/// proporsional terhadap `total`, dengan lubang putih di tengah.
class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.counts, required this.total});

  final Map<TaskCategory, int> counts;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const strokeWidth = 16.0;
    var startAngle = -math.pi / 2;

    for (final category in TaskCategory.values) {
      final count = counts[category] ?? 0;
      if (count == 0) continue;
      final sweep = (count / total) * 2 * math.pi;
      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.counts != counts || oldDelegate.total != total;
  }
}

/// Streak dihitung mundur dari hari ini: hari dengan tugas ber-tenggat yang
/// SEMUANYA selesai menambah streak; hari tanpa tugas dilewati (tidak
/// memutus streak); hari dengan tugas yang belum semua selesai memutus
/// streak. Batasi maksimal 60 hari ke belakang supaya tidak scan tak
/// terbatas kalau user sudah lama pakai app.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.tasks, required this.now});

  final List<TaskModel> tasks;
  final DateTime now;

  int get _streak {
    var streak = 0;
    for (var i = 0; i < 60; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final dayTasks = tasks.where((t) =>
          t.dueDate.year == day.year &&
          t.dueDate.month == day.month &&
          t.dueDate.day == day.day);
      if (dayTasks.isEmpty) continue;
      final allDone =
          dayTasks.every((t) => t.effectiveStatus == TaskStatus.completed);
      if (!allDone) break;
      streak++;
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final streak = _streak;
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
          const Text('Streak Belajar',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE8D6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_fire_department, color: Colors.orange),
              ),
              const SizedBox(width: 10),
              Text('$streak',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text('Hari', style: TextStyle(color: AppColors.textSecondaryOf(context))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            streak > 0
                ? 'Keren! Pertahankan streak-mu 🔥'
                : 'Selesaikan tugas hari ini untuk mulai streak 💪',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryOf(context)),
          ),
        ],
      ),
    );
  }
}

/// Kutipan motivasi berganti tiap hari (deterministik berdasar hari dalam
/// setahun) — murni konten dekoratif seperti pada desain Figma, tidak
/// datang dari data user.
class _MotivationCard extends StatelessWidget {
  const _MotivationCard({required this.now});

  final DateTime now;

  static const _quotes = [
    ('Kesuksesan adalah jumlah dari usaha kecil yang diulang setiap hari.', 'Robert Collier'),
    ('Jangan tunggu sampai siap, mulai saja dari sekarang.', 'Anonim'),
    ('Sedikit demi sedikit, lama-lama jadi bukit.', 'Peribahasa'),
    ('Fokus pada progres, bukan kesempurnaan.', 'Anonim'),
    ('Konsisten kecil setiap hari mengalahkan usaha besar sesekali.', 'Anonim'),
  ];

  @override
  Widget build(BuildContext context) {
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final quote = _quotes[dayOfYear % _quotes.length];

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
          const Text('Motivasi Hari Ini',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLightOf(context),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.format_quote, color: AppColors.primary, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            quote.$1,
            style: const TextStyle(fontSize: 11.5, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            '- ${quote.$2}',
            style: TextStyle(
                fontSize: 11, color: AppColors.textSecondaryOf(context), fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
