import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../core/extensions/date_time_extension.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/notification_model.dart';
import '../../models/notification_type.dart';
import '../../providers/notification_provider.dart';

/// Halaman Notifikasi, dirombak total mengikuti desain Figma: filter chip
/// kategori, dikelompokkan per hari (Hari ini/Kemarin/Sebelumnya), kartu
/// notifikasi dengan ikon & warna sesuai jenis, swipe-to-delete per item,
/// dan tombol hapus semua — jauh lebih kaya dari ListTile polos sebelumnya.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, required this.uid});

  final String uid;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationFilter _filter = NotificationFilter.semua;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().listenToNotifications(widget.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (provider.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus semua',
              onPressed: () => _confirmClearAll(context, provider),
            ),
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(NotificationProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const LoadingWidget();
    }
    if (provider.failure != null && provider.notifications.isEmpty) {
      return ErrorState(
        failure: provider.failure!,
        onRetry: () => provider.listenToNotifications(widget.uid),
      );
    }
    if (provider.notifications.isEmpty) {
      return const _EmptyNotifications();
    }

    final filtered = provider.notifications
        .where((n) => _filter.matches(n.type))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final groups = _groupByDay(filtered);

    return Column(
      children: [
        _FilterChipsRow(
          selected: _filter,
          onChanged: (f) => setState(() => _filter = f),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const _EmptyNotifications(filtered: true)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    for (final entry in groups.entries) ...[
                      _GroupHeader(
                        label: entry.key,
                        showMarkAllRead: entry.key == 'Hari ini' && provider.unreadCount > 0,
                        onMarkAllRead: () => provider.markAllAsRead(),
                      ),
                      const SizedBox(height: 8),
                      for (final notif in entry.value) ...[
                        _NotificationCard(
                          notification: notif,
                          groupLabel: entry.key,
                          onTap: () {
                            if (!notif.isRead) provider.markAsRead(notif.id);
                          },
                          onDelete: () => provider.deleteNotification(notif.id),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  /// Mengelompokkan notifikasi ke "Hari ini" / "Kemarin" / "Sebelumnya",
  /// dengan urutan grup dipertahankan (Hari ini dulu, baru Kemarin, baru
  /// Sebelumnya) — Map di Dart mempertahankan urutan insertion.
  Map<String, List<NotificationModel>> _groupByDay(List<NotificationModel> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final result = <String, List<NotificationModel>>{};
    for (final n in items) {
      final day = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      final label = day == today ? 'Hari ini' : (day == yesterday ? 'Kemarin' : 'Sebelumnya');
      result.putIfAbsent(label, () => []).add(n);
    }
    return result;
  }

  Future<void> _confirmClearAll(BuildContext context, NotificationProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus semua notifikasi?'),
        content: const Text('Semua notifikasi akan dihapus permanen dan tidak bisa dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.clearAll();
    }
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({required this.selected, required this.onChanged});

  final NotificationFilter selected;
  final ValueChanged<NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          for (final filter in NotificationFilter.values) ...[
            _FilterChip(
              label: filter.label,
              selected: selected == filter,
              onTap: () => onChanged(filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.dividerOf(context)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondaryOf(context),
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.showMarkAllRead, required this.onMarkAllRead});

  final String label;
  final bool showMarkAllRead;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
        if (showMarkAllRead)
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
            onPressed: onMarkAllRead,
            child: const Text('Tandai Semua Dibaca', style: TextStyle(fontSize: 12.5)),
          ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.groupLabel,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationModel notification;
  final String groupLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String get _timeLabel {
    if (groupLabel == 'Hari ini') return notification.createdAt.toDisplayTime;
    if (groupLabel == 'Kemarin') return 'Kemarin';
    final days = DateTime.now().difference(notification.createdAt).inDays;
    return days <= 1 ? '1 Hari lalu' : '$days Hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final type = notification.type;
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: notification.isRead ? AppColors.surfaceOf(context) : type.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerOf(context)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: type.color.withValues(alpha: 0.14), shape: BoxShape.circle),
                  child: Icon(type.icon, color: type.color, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(left: 6, top: 2),
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context), height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(_timeLabel, style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({this.filtered = false});

  /// true kalau kosong karena filter kategori, bukan karena benar-benar
  /// tidak ada notifikasi sama sekali — pesannya dibedakan supaya user
  /// tidak bingung kenapa notifikasi yang tadinya ada jadi "hilang".
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(color: AppColors.primaryLightOf(context), shape: BoxShape.circle),
                ),
                const Icon(Icons.notifications_rounded, size: 42, color: AppColors.primary),
                Positioned(
                  bottom: 10,
                  right: 18,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              filtered ? 'Tidak ada notifikasi di kategori ini' : 'Tidak ada notifikasi baru',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              filtered ? 'Coba pilih kategori lain di atas.' : 'Semua sudah update. Tetap semangat! 💪',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryOf(context)),
            ),
          ],
        ),
      ),
    );
  }
}
