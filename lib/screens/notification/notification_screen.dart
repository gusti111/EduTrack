import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_widget.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, required this.uid});

  final String uid;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
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
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllAsRead(),
              child: const Text('Tandai semua dibaca'),
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
      return const EmptyState(
        message: 'Belum ada notifikasi.',
        icon: Icons.notifications_none,
      );
    }

    return ListView.builder(
      itemCount: provider.notifications.length,
      itemBuilder: (context, index) {
        final notif = provider.notifications[index];
        return ListTile(
          leading: Icon(
            notif.isRead ? Icons.notifications_none : Icons.notifications_active,
            color: notif.isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            notif.title,
            style: TextStyle(
              fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Text(notif.body),
          onTap: () {
            if (!notif.isRead) provider.markAsRead(notif.id);
          },
        );
      },
    );
  }
}
