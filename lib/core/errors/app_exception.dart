import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'failure.dart';

/// Exception generik yang dilempar dari lapisan Service, sebelum
/// diterjemahkan Repository menjadi [Failure].
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Helper dipakai di Repository: ubah exception mentah (apapun sumbernya)
/// menjadi [Failure] yang konsisten untuk dikonsumsi Provider/UI.
Failure mapExceptionToFailure(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'unavailable':
        return const NetworkFailure();
      case 'permission-denied':
        return const AuthFailure('Kamu tidak punya akses untuk aksi ini.');
      case 'not-found':
        return const NotFoundFailure();
      default:
        return ServerFailure(error.message ?? 'Kesalahan Firestore: ${error.code}');
    }
  }
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure('Email atau kata sandi salah.');
      case 'email-already-in-use':
        return const AuthFailure('Email ini sudah terdaftar.');
      case 'weak-password':
        return const AuthFailure('Kata sandi terlalu lemah (minimal 6 karakter).');
      case 'invalid-email':
        return const AuthFailure('Format email tidak valid.');
      case 'network-request-failed':
        return const NetworkFailure();
      default:
        return AuthFailure(error.message ?? 'Kesalahan autentikasi.');
    }
  }
  if (error is AppException) {
    return ServerFailure(error.message);
  }
  return const UnknownFailure();
}
