import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/constants/firestore_paths.dart';

/// Lapisan paling bawah: hanya tahu soal Firestore, tidak tahu soal
/// TaskModel atau Failure. Kalau nanti backend berganti, cukup file ini
/// (dan implementasinya di Repository) yang disentuh.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    // Aktifkan persistent cache supaya task tetap bisa dibaca saat offline
    // (dipakai bersama ConnectivityProvider yang sudah mendeteksi jaringan).
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      _firestore.collection(FirestorePaths.tasks);

  /// Stream realtime task milik satu user, diurutkan berdasarkan tenggat.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchTasks(String uid) {
    return _tasksRef
        .where(FirestorePaths.fieldUid, isEqualTo: uid)
        .orderBy(FirestorePaths.fieldDueDate)
        .snapshots();
  }

  Future<DocumentReference<Map<String, dynamic>>> addTask(
    Map<String, dynamic> data,
  ) {
    return _tasksRef.add(data);
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) {
    return _tasksRef.doc(taskId).update(data);
  }

  Future<void> deleteTask(String taskId) {
    return _tasksRef.doc(taskId).delete();
  }
}
