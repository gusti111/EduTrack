import '../../app/constants/firestore_paths.dart';
import '../network/firestore_rest_client.dart';
import '../network/polling_stream.dart';

/// Catatan: ini notifikasi IN-APP (disimpan & dibaca dari Firestore),
/// bukan push notification. Kalau nanti butuh push beneran (muncul walau
/// app tertutup), tambahkan `firebase_messaging` + `flutter_local_notifications`
/// di pubspec — lapisan Repository/Provider di atas ini tidak perlu berubah,
/// cukup service ini yang diperluas.
///
/// MIGRASI: sama seperti FirestoreService — pakai FirestoreRestClient
/// (REST, bukan gRPC/WebChannel), dan watchNotifications diakali lewat
/// polling, bukan `snapshots()`.
class NotificationService {
  NotificationService({FirestoreRestClient? client})
      : _client = client ?? FirestoreRestClient();

  final FirestoreRestClient _client;

  static const Duration _pollInterval = Duration(seconds: 5);

  Stream<List<MapEntry<String, Map<String, dynamic>>>> watchNotifications(
    String uid,
  ) {
    return pollingStream(
      interval: _pollInterval,
      fetch: () => _client.runQuery(
        collection: FirestorePaths.notifications,
        whereField: FirestorePaths.fieldUid,
        whereEquals: uid,
        orderByField: 'createdAt',
        descending: true,
      ),
    );
  }

  Future<void> markAsRead(String notificationId) {
    return _client.updateFields(
      FirestorePaths.notifications,
      notificationId,
      {'isRead': true},
    );
  }

  /// REST API Firestore tidak punya operasi batch seperti SDK biasa —
  /// tiap dokumen di-update satu-satu secara paralel lewat Future.wait.
  Future<void> markAllAsRead(List<String> notificationIds) async {
    await Future.wait(
      notificationIds.map((id) => markAsRead(id)),
    );
  }

  Future<void> deleteNotification(String notificationId) {
    return _client.deleteDocument(
      FirestorePaths.notifications,
      notificationId,
    );
  }

  /// Sama seperti [markAllAsRead]: tidak ada operasi batch delete di REST
  /// API, jadi tiap dokumen dihapus satu-satu secara paralel.
  Future<void> deleteAll(List<String> notificationIds) async {
    await Future.wait(
      notificationIds.map((id) => deleteNotification(id)),
    );
  }
}
