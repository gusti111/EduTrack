import '../../app/constants/firestore_paths.dart';
import '../network/firestore_rest_client.dart';
import '../network/polling_stream.dart';

/// Lapisan paling bawah: hanya tahu soal Firestore, tidak tahu soal
/// TaskModel atau Failure. Kalau nanti backend berganti, cukup file ini
/// (dan implementasinya di Repository) yang disentuh.
///
/// MIGRASI: sebelumnya pakai package `cloud_firestore` (gRPC/WebChannel),
/// yang terbukti macet konsisten di lingkungan tertentu (lihat komentar
/// panjang di FirestoreRestClient). Sekarang pakai REST API biasa lewat
/// [FirestoreRestClient] — konsekuensinya: tidak ada `snapshots()`
/// realtime bawaan, jadi [watchTasks] diakali lewat polling berkala
/// (lihat [pollingStream]), bukan koneksi streaming.
class FirestoreService {
  FirestoreService({FirestoreRestClient? client})
      : _client = client ?? FirestoreRestClient();

  final FirestoreRestClient _client;

  // Interval polling untuk watchTasks. 5 detik dianggap cukup responsif
  // untuk task planner personal (bukan aplikasi kolaborasi live) tanpa
  // membebani kuota Firestore REST dengan request yang terlalu sering.
  static const Duration _pollInterval = Duration(seconds: 5);

  /// "Stream realtime" (sebenarnya polling tiap [_pollInterval]) berisi
  /// task milik satu user, diurutkan berdasarkan tenggat. Return berupa
  /// MapEntry(docId, fields) — bentuk yang sama seperti runQuery di
  /// FirestoreRestClient, supaya konversi ke TaskModel tetap tanggung
  /// jawab TaskRepository, bukan di sini.
  Stream<List<MapEntry<String, Map<String, dynamic>>>> watchTasks(
    String uid,
  ) {
    return pollingStream(
      interval: _pollInterval,
      fetch: () => _client.runQuery(
        collection: FirestorePaths.tasks,
        whereField: FirestorePaths.fieldUid,
        whereEquals: uid,
        orderByField: FirestorePaths.fieldDueDate,
      ),
    );
  }

  Future<String> addTask(Map<String, dynamic> data) {
    return _client.addDocument(FirestorePaths.tasks, data);
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) {
    return _client.updateFields(FirestorePaths.tasks, taskId, data);
  }

  Future<void> deleteTask(String taskId) {
    return _client.deleteDocument(FirestorePaths.tasks, taskId);
  }
}
