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
    return _firestoreService.watchTasks(uid).map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
          .toList();
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
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      await _firestoreService.updateTask(task.id, task.toMap());
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestoreService.deleteTask(taskId);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }
}
