import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/constants/firestore_paths.dart';

/// Catatan: ini notifikasi IN-APP (disimpan & dibaca dari Firestore),
/// bukan push notification. Kalau nanti butuh push beneran (muncul walau
/// app tertutup), tambahkan `firebase_messaging` + `flutter_local_notifications`
/// di pubspec — lapisan Repository/Provider di atas ini tidak perlu berubah,
/// cukup service ini yang diperluas.
class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifRef =>
      _firestore.collection(FirestorePaths.notifications);

  Stream<QuerySnapshot<Map<String, dynamic>>> watchNotifications(String uid) {
    return _notifRef
        .where(FirestorePaths.fieldUid, isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String notificationId) {
    return _notifRef.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(List<String> notificationIds) async {
    final batch = _firestore.batch();
    for (final id in notificationIds) {
      batch.update(_notifRef.doc(id), {'isRead': true});
    }
    await batch.commit();
  }
}
