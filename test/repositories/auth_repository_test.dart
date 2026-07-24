import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:edutrack/core/errors/failure.dart';
import 'package:edutrack/core/services/auth_service.dart';
import 'package:edutrack/repositories/auth_repository.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockAuthService mockAuthService;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockAuthService = MockAuthService();
    repository = AuthRepositoryImpl(mockAuthService);
  });

  group('AuthRepositoryImpl', () {
    const tEmail = 'mahasiswa@polnep.ac.id';
    const tPassword = 'password123';
    const tUid = 'user_abc_123';
    const tDisplayName = 'Gusty Faqikh';

    test('login - meneruskan email (trimmed) & password ke AuthService',
        () async {
      final mockCredential = MockUserCredential();
      when(() => mockAuthService.signIn(tEmail, tPassword))
          .thenAnswer((_) async => mockCredential);

      await repository.login(' $tEmail ', tPassword);

      verify(() => mockAuthService.signIn(tEmail, tPassword)).called(1);
    });

    test('login - melempar Failure saat AuthService melempar exception',
        () async {
      when(() => mockAuthService.signIn(tEmail, tPassword)).thenThrow(
        FirebaseAuthException(
          code: 'invalid-credential',
          message: 'Kredensial salah',
        ),
      );

      expect(
        () => repository.login(tEmail, tPassword),
        throwsA(isA<Failure>()),
      );
    });

    test('register - membuat kredensial auth lalu dokumen profil di Firestore',
        () async {
      final mockCredential = MockUserCredential();
      final mockUser = MockUser();

      when(() => mockUser.uid).thenReturn(tUid);
      when(() => mockCredential.user).thenReturn(mockUser);
      when(() => mockAuthService.register(tEmail, tPassword))
          .thenAnswer((_) async => mockCredential);
      when(() => mockAuthService.createUserDoc(tUid, any()))
          .thenAnswer((_) async {});

      await repository.register(tEmail, tPassword, displayName: tDisplayName);

      verify(() => mockAuthService.register(tEmail, tPassword)).called(1);
      verify(() => mockAuthService.createUserDoc(tUid, any())).called(1);
    });

    test('register - melempar Failure saat pembuatan dokumen profil gagal',
        () async {
      final mockCredential = MockUserCredential();
      final mockUser = MockUser();

      when(() => mockUser.uid).thenReturn(tUid);
      when(() => mockCredential.user).thenReturn(mockUser);
      when(() => mockAuthService.register(tEmail, tPassword))
          .thenAnswer((_) async => mockCredential);
      when(() => mockAuthService.createUserDoc(tUid, any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      expect(
        () => repository.register(tEmail, tPassword, displayName: tDisplayName),
        throwsA(isA<Failure>()),
      );
    });

    test('getUserProfile - mengembalikan UserModel jika dokumen ditemukan',
        () async {
      final mockDoc = MockDocumentSnapshot();
      final tData = {
        'email': tEmail,
        'displayName': tDisplayName,
        'createdAt': '2026-01-01T00:00:00.000',
      };

      when(() => mockDoc.exists).thenReturn(true);
      when(() => mockDoc.data()).thenReturn(tData);
      when(() => mockAuthService.getUserDoc(tUid))
          .thenAnswer((_) async => mockDoc);

      final result = await repository.getUserProfile(tUid);

      expect(result, isNotNull);
      expect(result?.uid, tUid);
      expect(result?.email, tEmail);
      expect(result?.displayName, tDisplayName);
    });

    test('getUserProfile - mengembalikan null jika dokumen tidak ditemukan',
        () async {
      final mockDoc = MockDocumentSnapshot();
      when(() => mockDoc.exists).thenReturn(false);
      when(() => mockDoc.data()).thenReturn(null);
      when(() => mockAuthService.getUserDoc(tUid))
          .thenAnswer((_) async => mockDoc);

      final result = await repository.getUserProfile(tUid);

      expect(result, isNull);
    });

    test('updateDisplayName - memanggil updateUserDoc dengan field yang benar',
        () async {
      when(() => mockAuthService.updateUserDoc(tUid, any()))
          .thenAnswer((_) async {});

      await repository.updateDisplayName(tUid, tDisplayName);

      verify(() => mockAuthService.updateUserDoc(
            tUid,
            {'displayName': tDisplayName},
          )).called(1);
    });

    test('logout - memanggil signOut pada AuthService', () async {
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      await repository.logout();

      verify(() => mockAuthService.signOut()).called(1);
    });
  });
}
