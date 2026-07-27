import 'package:firebase_auth/firebase_auth.dart' show UserCredential;
import 'package:flutter/foundation.dart' show debugPrint;

import '../core/errors/app_exception.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Stream<String?> get authStateChanges;
  String? get currentUid;
  String? get currentEmail;

  Future<void> login(String email, String password);
  Future<void> loginWithGoogle();
  Future<void> register(String email, String password, {String? displayName});
  Future<void> sendPasswordReset(String email);
  Future<void> logout();
  Future<UserModel?> getUserProfile(String uid);
  Future<void> updateDisplayName(String uid, String displayName);

  /// Update beberapa field profil sekaligus (nama, gender, tanggal lahir,
  /// status, semester, telepon, alamat) dalam satu kali tulis ke Firestore —
  /// dipakai oleh EditProfileScreen versi lengkap.
  Future<void> updateProfileFields(String uid, Map<String, dynamic> fields);
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._authService);

  final AuthService _authService;

  @override
  Stream<String?> get authStateChanges =>
      _authService.authStateChanges.map((user) => user?.uid);

  @override
  String? get currentUid => _authService.currentUser?.uid;

  @override
  String? get currentEmail => _authService.currentUser?.email;

  @override
  Future<void> login(String email, String password) async {
    try {
      await _authService.signIn(email.trim(), password);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> loginWithGoogle() async {
    final UserCredential? credential;
    try {
      credential = await _authService.signInWithGoogle();
    } catch (e) {
      throw mapExceptionToFailure(e);
    }

    // Null artinya user membatalkan sendiri (tutup popup/picker akun) —
    // bukan kegagalan, jadi berhenti di sini tanpa melempar Failure.
    // UI (GoogleSignInButton) memperlakukan ini sama seperti aksi sukses
    // yang "tidak melakukan apa-apa": tidak ada snackbar error.
    final user = credential?.user;
    if (user == null) return;

    // Dokumen profil di koleksi `users` mungkin belum ada kalau ini
    // login Google PERTAMA KALI (setara "register otomatis"). Kalau
    // sudah ada (user lama), jangan ditimpa — biar data yang sudah
    // di-edit manual di EditProfileScreen tidak hilang.
    try {
      final existing = await _authService.getUserDoc(user.uid);
      if (existing == null) {
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          createdAt: DateTime.now(),
        );
        await _authService.createUserDoc(user.uid, userModel.toMap());
      }
    } catch (e) {
      // Sama seperti register(): kegagalan tulis dokumen profil TIDAK
      // BOLEH membatalkan login — akun Auth sudah valid.
      debugPrint(
        '⚠️ [AuthRepository.loginWithGoogle] gagal cek/membuat dokumen '
        'profil untuk ${user.uid}: $e',
      );
    }
  }

  @override
  Future<void> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    // Akun Auth adalah prioritas utama. Bagian ini SENGAJA tidak dibungkus
    // satu try-catch besar bersama pembuatan dokumen profil: kalau
    // createUserWithEmailAndPassword sendiri yang gagal (email dipakai,
    // password lemah, dll), itu satu-satunya kasus yang boleh membatalkan
    // register dan melempar error ke UI.
    final UserCredential credential;
    try {
      credential = await _authService.register(email.trim(), password);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }

    final uid = credential.user!.uid;

    // Paksa token ID auth ter-refresh sebelum menulis dokumen profil.
    // Tanpa ini, ada celah waktu singkat di mana klien masih memegang
    // token lama/belum ada saat request `set()` ke Firestore dikirim,
    // sehingga security rules yang mensyaratkan `request.auth.uid`
    // bisa diam-diam menolak penulisan tanpa error yang jelas.
    try {
      await credential.user?.getIdToken(true);
    } catch (_) {
      // Kalau refresh token gagal (mis. baru saja offline), tetap lanjut
      // coba tulis dokumen profil di bawah — biar blok berikut yang
      // menentukan nasibnya, bukan langkah pencegahan ini.
    }

    final userModel = UserModel(
      uid: uid,
      email: email.trim(),
      displayName: displayName,
      createdAt: DateTime.now(),
    );

    // Dokumen profil di koleksi `users`, terpisah dari data auth Firebase.
    // Kegagalan di sini (mis. timeout tulis) TIDAK BOLEH membatalkan
    // login/register: akun Auth sudah valid dan user harus tetap bisa
    // masuk. Kegagalan dicatat secara internal saja; layar Profil akan
    // memakai data default (nama kosong) sampai dokumen berhasil ditulis
    // ulang, misalnya lewat EditProfileScreen.
    try {
      await _authService.createUserDoc(uid, userModel.toMap());
    } catch (e) {
      debugPrint(
        '⚠️ [AuthRepository.register] gagal membuat dokumen profil untuk '
        '$uid, akun Auth tetap dianggap berhasil dibuat: $e',
      );
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email.trim());
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _authService.signOut();
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final data = await _authService.getUserDoc(uid);
      if (data == null) return null;
      return UserModel.fromMap(data, uid);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> updateDisplayName(String uid, String displayName) async {
    try {
      await _authService.updateUserDoc(uid, {'displayName': displayName});
    } catch (e) {
      throw mapExceptionToFailure(e, isWrite: true);
    }
  }

  @override
  Future<void> updateProfileFields(
    String uid,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _authService.updateUserDoc(uid, fields);
    } catch (e) {
      throw mapExceptionToFailure(e, isWrite: true);
    }
  }
}
