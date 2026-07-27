import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:edutrack/core/errors/failure.dart';
import 'package:edutrack/core/network/firestore_rest_client.dart';
import 'package:edutrack/core/services/firestore_service.dart';
import 'package:edutrack/models/task_model.dart';
import 'package:edutrack/models/task_priority.dart';
import 'package:edutrack/models/task_status.dart';
import 'package:edutrack/repositories/task_repository.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late MockFirestoreService mockFirestoreService;
  late TaskRepositoryImpl repository;

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    repository = TaskRepositoryImpl(mockFirestoreService);
  });

  group('TaskRepositoryImpl', () {
    const tUid = 'user_123';
    const tTaskId = 'task_xyz';
    final tTask = TaskModel(
      id: tTaskId,
      uid: tUid,
      title: 'Desain Antarmuka Mobile',
      subject: 'Design UI/UX',
      description: 'Implementasi widget kalender interaktif',
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      dueDate: DateTime(2026, 8, 10),
      createdAt: DateTime(2026, 7, 20),
    );

    test('addTask - meneruskan hasil toMap() ke FirestoreService.addTask',
        () async {
      when(() => mockFirestoreService.addTask(any()))
          .thenAnswer((_) async => tTaskId);

      await repository.addTask(tTask);

      verify(() => mockFirestoreService.addTask(tTask.toMap())).called(1);
    });

    test('addTask - melempar Failure saat FirestoreService gagal', () async {
      when(() => mockFirestoreService.addTask(any())).thenThrow(
        const FirestoreRestException(statusCode: 503, message: 'unavailable'),
      );

      expect(() => repository.addTask(tTask), throwsA(isA<Failure>()));
    });

    test('updateTask - memanggil updateTask dengan id & data yang benar',
        () async {
      when(() => mockFirestoreService.updateTask(tTaskId, any()))
          .thenAnswer((_) async {});

      await repository.updateTask(tTask);

      verify(() => mockFirestoreService.updateTask(tTaskId, tTask.toMap()))
          .called(1);
    });

    test('deleteTask - memanggil deleteTask dengan id yang benar', () async {
      when(() => mockFirestoreService.deleteTask(tTaskId))
          .thenAnswer((_) async {});

      await repository.deleteTask(tTaskId);

      verify(() => mockFirestoreService.deleteTask(tTaskId)).called(1);
    });

    test(
        'watchTasks - mentransformasi hasil polling FirestoreService menjadi '
        'List<TaskModel>', () async {
      final tData = {
        'uid': tUid,
        'title': 'Desain Antarmuka Mobile',
        'description': 'Implementasi widget kalender interaktif',
        'status': 'inProgress',
        'priority': 'high',
        'dueDate': DateTime(2026, 8, 10).toIso8601String(),
        'createdAt': DateTime(2026, 7, 20).toIso8601String(),
      };

      when(() => mockFirestoreService.watchTasks(tUid)).thenAnswer(
        (_) => Stream.value([MapEntry(tTaskId, tData)]),
      );

      final stream = repository.watchTasks(tUid);

      await expectLater(
        stream,
        emits(
          isA<List<TaskModel>>()
              .having((list) => list.length, 'length', 1)
              .having((list) => list.first.id, 'first.id', tTaskId)
              .having((list) => list.first.uid, 'first.uid', tUid),
        ),
      );
    });

    test(
        'watchTasks - melewati dokumen cacat, tetap mengembalikan sisa '
        'dokumen yang valid', () async {
      final tGoodData = {
        'uid': tUid,
        'title': 'Tugas Valid',
        'status': 'pending',
        'priority': 'high',
        'dueDate': DateTime(2026, 8, 10).toIso8601String(),
        'createdAt': DateTime(2026, 7, 20).toIso8601String(),
      };
      // dueDate kosong/rusak — sebelumnya ini diam-diam menjadi
      // DateTime.now() dan meloloskan dokumen; sekarang harus dilewati.
      final tCorruptData = {
        'uid': tUid,
        'title': 'Tugas Rusak',
        'status': 'pending',
        'priority': 'high',
        'createdAt': DateTime(2026, 7, 20).toIso8601String(),
      };

      when(() => mockFirestoreService.watchTasks(tUid)).thenAnswer(
        (_) => Stream.value([
          MapEntry(tTaskId, tGoodData),
          MapEntry('task_corrupt', tCorruptData),
        ]),
      );

      final stream = repository.watchTasks(tUid);

      await expectLater(
        stream,
        emits(
          isA<List<TaskModel>>()
              .having((list) => list.length, 'length', 1)
              .having((list) => list.first.id, 'first.id', tTaskId),
        ),
      );
    });

    test(
        'addTask - TimeoutException dipetakan ke PendingSyncFailure, bukan '
        'NetworkFailure (offline-first: data sudah di local cache)',
        () async {
      when(() => mockFirestoreService.addTask(any()))
          .thenThrow(TimeoutException('timeout'));

      await expectLater(
        repository.addTask(tTask),
        throwsA(isA<PendingSyncFailure>()),
      );
    });

    test('watchTasks - meneruskan error Firestore sebagai Failure', () async {
      when(() => mockFirestoreService.watchTasks(tUid)).thenAnswer(
        (_) => Stream<List<MapEntry<String, Map<String, dynamic>>>>.error(
          const FirestoreRestException(statusCode: 503, message: 'unavailable'),
        ),
      );

      final stream = repository.watchTasks(tUid);

      await expectLater(stream, emitsError(isA<Failure>()));
    });
  });
}
