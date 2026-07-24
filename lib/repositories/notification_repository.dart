import '../core/errors/app_exception.dart';
import '../core/services/notification_service.dart';
import '../models/notification_model.dart';

abstract class NotificationRepository {
  Stream<List<NotificationModel>> watchNotifications(String uid);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(List<String> notificationIds);
}

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._service);

  final NotificationService _service;

  @override
  Stream<List<NotificationModel>> watchNotifications(String uid) {
    return _service.watchNotifications(uid).map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((error) {
      throw mapExceptionToFailure(error);
    });
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> markAllAsRead(List<String> notificationIds) async {
    try {
      await _service.markAllAsRead(notificationIds);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }
}
