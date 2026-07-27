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

  /// Optimistic update: notifikasi langsung hilang dari list saat itu juga
  /// (mis. dari swipe-to-delete) — polling stream akan mengonfirmasi ulang
  /// beberapa detik kemudian, tapi user tidak perlu menunggu round-trip
  /// network untuk melihat hasilnya.
  Future<void> deleteNotification(String id) async {
    final previous = _notifications;
    _notifications = _notifications.where((n) => n.id != id).toList();
    notifyListeners();

    try {
      await _repository.deleteNotification(id);
    } catch (e) {
      // Gagal hapus di server -> kembalikan tampilan seperti semula.
      _notifications = previous;
      _failure = e is Failure ? e : const UnknownFailure();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearAll() async {
    final ids = _notifications.map((n) => n.id).toList();
    final previous = _notifications;
    _notifications = [];
    notifyListeners();

    try {
      await _repository.deleteAll(ids);
    } catch (e) {
      _notifications = previous;
      _failure = e is Failure ? e : const UnknownFailure();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
