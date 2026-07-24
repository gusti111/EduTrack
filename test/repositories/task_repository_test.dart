import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:edutrack/core/errors/failure.dart';
import 'package:edutrack/core/services/firestore_service.dart';
import 'package:edutrack/models/task_model.dart';
import 'package:edutrack/models/task_priority.dart';
import 'package:edutrack/models/task_status.dart';
import 'package:edutrack/repositories/task_repository.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

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
      description: 'Implementasi widget kalender interaktif',
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      dueDate: DateTime(2026, 8, 10),
      createdAt: DateTime(2026, 7, 20),
    );

    test('addTask - meneruskan hasil toMap() ke FirestoreService.addTask',
        () async {
      final mockDocRef = MockDocumentReference();
      when(() => mockFirestoreService.addTask(any()))
          .thenAnswer((_) async => mockDocRef);

      await repository.addTask(tTask);

      verify(() => mockFirestoreService.addTask(tTask.toMap())).called(1);
    });

    test('addTask - melempar Failure saat FirestoreService gagal', () async {
      when(() => mockFirestoreService.addTask(any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
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
        'watchTasks - mentransformasi QuerySnapshot Firestore menjadi List<TaskModel>',
        () async {
      final mockSnapshot = MockQuerySnapshot();
      final mockDoc = MockQueryDocumentSnapshot();

      final tData = {
        'uid': tUid,
        'title': 'Desain Antarmuka Mobile',
        'description': 'Implementasi widget kalender interaktif',
        'status': 'inProgress',
        'priority': 'high',
        'dueDate': Timestamp.fromDate(DateTime(2026, 8, 10)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 7, 20)),
      };

      when(() => mockDoc.id).thenReturn(tTaskId);
      when(() => mockDoc.data()).thenReturn(tData);
      when(() => mockSnapshot.docs).thenReturn([mockDoc]);

      when(() => mockFirestoreService.watchTasks(tUid))
          .thenAnswer((_) => Stream.value(mockSnapshot));

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

    test('watchTasks - meneruskan error Firestore sebagai Failure', () async {
      when(() => mockFirestoreService.watchTasks(tUid)).thenAnswer(
        (_) => Stream<QuerySnapshot<Map<String, dynamic>>>.error(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        ),
      );

      final stream = repository.watchTasks(tUid);

      await expectLater(stream, emitsError(isA<Failure>()));
    });
  });
}
