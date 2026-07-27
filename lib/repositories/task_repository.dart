import 'package:flutter/foundation.dart' show debugPrint;

import '../core/errors/app_exception.dart';
import '../core/services/firestore_service.dart';
import '../models/task_model.dart';

/// Provider hanya bicara dengan interface ini — tidak pernah tahu
/// bahwa di baliknya ada Firestore. Memudahkan testing (tinggal bikin
/// FakeTaskRepository) dan migrasi backend di masa depan.
abstract class TaskRepository {
  Stream<List<TaskModel>> watchTasks(String uid);
  Future<void> addTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String taskId);
}

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Stream<List<TaskModel>> watchTasks(String uid) {
    return _firestoreService.watchTasks(uid).map((entries) {
      // Konversi per-dokumen, bukan lewat satu .map() sekaligus: satu
      // dokumen cacat (mis. field priority berubah tipe, atau field wajib
      // kosong karena intervensi manual di Firebase Console) tidak boleh
      // melempar exception yang merusak seluruh stream dan membuat 99
      // dokumen valid lainnya ikut gagal ditampilkan.
      final tasks = <TaskModel>[];
      for (final entry in entries) {
        try {
          tasks.add(TaskModel.fromMap(entry.value, entry.key));
        } catch (e) {
          debugPrint(
            '⚠️ [TaskRepository.watchTasks] dokumen ${entry.key} dilewati, '
            'gagal di-parse: $e',
          );
        }
      }
      return tasks;
    }).handleError((error) {
      // Diteruskan sebagai Failure supaya Provider tidak perlu tahu
      // detail exception Firestore.
      throw mapExceptionToFailure(error);
    });
  }

  @override
  Future<void> addTask(TaskModel task) async {
    try {
      await _firestoreService.addTask(task.toMap());
    } catch (e) {
      throw mapExceptionToFailure(e, isWrite: true);
    }
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      await _firestoreService.updateTask(task.id, task.toMap());
    } catch (e) {
      throw mapExceptionToFailure(e, isWrite: true);
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestoreService.deleteTask(taskId);
    } catch (e) {
      throw mapExceptionToFailure(e, isWrite: true);
    }
  }
}
