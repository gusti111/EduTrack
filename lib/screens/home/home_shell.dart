import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/task_provider.dart';
import '../calendar/calendar_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../statistics/statistics_screen.dart';
import '../tasks/task_list_screen.dart';

/// Shell dengan bottom navigation. Satu-satunya tempat yang memanggil
/// `listenToTasks` — tab lain (Home, Statistics) tinggal baca
/// `context.watch<TaskProvider>()` tanpa perlu subscribe ulang.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.uid});

  final String uid;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().listenToTasks(widget.uid);
      context.read<NotificationProvider>().listenToNotifications(widget.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(uid: widget.uid),
      TaskListScreen(uid: widget.uid),
      CalendarScreen(uid: widget.uid),
      const StatisticsScreen(),
      const ProfileScreen(),
    ];

    final isOnline = context.watch<ConnectivityProvider>().isOnline;

    return Scaffold(
      body: Column(
        children: [
          if (!isOnline) const _OfflineBanner(),
          Expanded(child: IndexedStack(index: _index, children: pages)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.task_outlined),
              selectedIcon: Icon(Icons.task),
              label: 'Tugas'),
          NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Kalender'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Statistik'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil'),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warning,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: const Text(
        'Tidak ada koneksi internet',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
