import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/failure.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._repository);

  final NotificationRepository _repository;
  StreamSubscription<List<NotificationModel>>? _subscription;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  Failure? _failure;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;
  Failure? get failure => _failure;

  void listenToNotifications(String uid) {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _repository.watchNotifications(uid).listen(
      (items) {
        _notifications = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _failure = error is Failure ? error : const UnknownFailure();
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String id) => _repository.markAsRead(id);

  Future<void> markAllAsRead() {
    final unreadIds =
        _notifications.where((n) => !n.isRead).map((n) => n.id).toList();
    return _repository.markAllAsRead(unreadIds);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
