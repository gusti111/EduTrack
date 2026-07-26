import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

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
  // TEMPORARY DEBUG LOG — hapus setelah akar masalah timeout ketemu.
  // Ini nunjukin JENIS ASLI error-nya di Console, sebelum diterjemahkan
  // jadi pesan generic "gagal koneksi" ke UI. Kalau error ini
  // TimeoutException, berarti benar operasi Firestore-nya macet lebih
  // dari 15 detik. Kalau ternyata FirebaseException dengan code lain
  // (mis. 'unavailable', 'permission-denied'), akar masalahnya beda.
  debugPrint(
    '🔴 [mapExceptionToFailure] runtimeType=${error.runtimeType} '
    'error=$error'
    '${error is FirebaseException ? ' code=${error.code}' : ''}',
  );

  // Operasi yang macet lebih dari batas waktu (lihat `_writeTimeout` di
  // AuthService/FirestoreService) berakhir sebagai TimeoutException, bukan
  // FirebaseException — wajib dicek duluan supaya tidak jatuh ke pesan
  // generic "Terjadi kesalahan yang tidak diketahui".
  if (error is TimeoutException) {
    return const NetworkFailure(
      'Permintaan butuh waktu terlalu lama. Periksa koneksi internet kamu lalu coba lagi.',
    );
  }
  // PENTING: FirebaseAuthException adalah subclass dari FirebaseException.
  // Kalau blok `error is FirebaseException` diperiksa duluan, blok
  // `error is FirebaseAuthException` di bawahnya TIDAK PERNAH tercapai —
  // semua error login/register (password salah, email sudah terdaftar, dll)
  // akan selalu jatuh ke pesan generic "Kesalahan Firestore" alih-alih
  // pesan ramah yang seharusnya. Maka FirebaseAuthException wajib dicek
  // LEBIH DULU, baru FirebaseException yang lebih umum.
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
  if (error is AppException) {
    return ServerFailure(error.message);
  }
  return const UnknownFailure();
}
