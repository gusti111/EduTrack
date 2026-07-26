import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/constants/firestore_paths.dart';

/// Lapisan paling bawah: hanya tahu soal Firestore, tidak tahu soal
/// TaskModel atau Failure. Kalau nanti backend berganti, cukup file ini
/// (dan implementasinya di Repository) yang disentuh.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  // Pengaturan Settings (persistence, long-polling) TIDAK ditaruh di sini.
  // Lihat lib/bootstrap.dart — harus jadi sentuhan pertama ke Firestore
  // di seluruh app, sebelum AuthService/FirestoreService manapun dibuat.

  final FirebaseFirestore _firestore;

  // Batas waktu wajar untuk operasi tulis. Kalau backend/SDK macet tanpa
  // melempar exception (kasus nyata yang pernah terjadi di atas), user
  // tetap dapat pesan error yang jelas alih-alih tombol loading selamanya.
  static const Duration _writeTimeout = Duration(seconds: 15);

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
    return _tasksRef.add(data).timeout(_writeTimeout);
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) {
    return _tasksRef.doc(taskId).update(data).timeout(_writeTimeout);
  }

  Future<void> deleteTask(String taskId) {
    return _tasksRef.doc(taskId).delete().timeout(_writeTimeout);
  }
}
