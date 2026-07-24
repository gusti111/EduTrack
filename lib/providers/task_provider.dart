import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/failure.dart';
import '../models/task_model.dart';
import '../models/task_status.dart';
import '../repositories/task_repository.dart';

/// UI hanya membaca 3 hal dari sini: [isLoading], [failure], [tasks].
/// Tidak pernah tahu soal Firestore sama sekali.
class TaskProvider extends ChangeNotifier {
  TaskProvider(this._repository);

  final TaskRepository _repository;
  StreamSubscription<List<TaskModel>>? _subscription;

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  Failure? _failure;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  Failure? get failure => _failure;

  /// Mulai mendengarkan task milik [uid] secara realtime.
  /// Panggil sekali, misalnya di initState halaman task list.
  void listenToTasks(String uid) {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _repository.watchTasks(uid).listen(
      (tasks) {
        _tasks = tasks;
        _isLoading = false;
        _failure = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _failure = error is Failure ? error : const UnknownFailure();
        notifyListeners();
      },
    );
  }

  List<TaskModel> tasksByStatus(TaskStatus status) =>
      _tasks.where((t) => t.status == status).toList();

  Future<bool> addTask(TaskModel task) => _mutate(() => _repository.addTask(task));

  Future<bool> updateTask(TaskModel task) =>
      _mutate(() => _repository.updateTask(task));

  Future<bool> deleteTask(String taskId) =>
      _mutate(() => _repository.deleteTask(taskId));

  /// Helper supaya add/update/delete punya pola error handling yang sama:
  /// return true kalau sukses, set [failure] dan return false kalau gagal.
  Future<bool> _mutate(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (e) {
      _failure = e is Failure ? e : const UnknownFailure();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
