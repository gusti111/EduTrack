import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../app/constants/firestore_paths.dart';
import '../network/firestore_rest_client.dart';

/// Lapisan paling bawah untuk auth: hanya tahu soal FirebaseAuth/Firestore,
/// tidak tahu soal UserModel atau Failure.
///
/// MIGRASI: FirebaseAuth SENGAJA TIDAK diubah — dari diagnosa sebelumnya,
/// operasi Auth (login/register/reset password) selalu lancar karena
/// memang cuma HTTP request-response biasa di baliknya, bukan streaming.
/// Yang macet konsisten adalah Firestore lewat SDK `cloud_firestore`
/// (gRPC/WebChannel), makanya HANYA bagian dokumen profil user (users/{uid})
/// yang dipindah ke [FirestoreRestClient].
class AuthService {
  AuthService({FirebaseAuth? auth, FirestoreRestClient? firestoreClient})
      : _auth = auth ?? FirebaseAuth.instance,
        _client = firestoreClient ?? FirestoreRestClient();

  final FirebaseAuth _auth;
  final FirestoreRestClient _client;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Login/daftar otomatis pakai akun Google.
  ///
  /// Return null (bukan exception) kalau user MEMBATALKAN sendiri lewat
  /// popup/picker akun — itu bukan kegagalan, jadi tidak perlu ditampilkan
  /// sebagai error di UI.
  ///
  /// Di Web: pakai `signInWithPopup` bawaan firebase_auth — tidak perlu
  /// package google_sign_in ataupun client ID tambahan di index.html.
  /// Di Android/iOS: firebase_auth tidak punya popup native, jadi harus
  /// lewat package google_sign_in dulu untuk dapat token, baru ditukar ke
  /// credential Firebase lewat signInWithCredential.
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      try {
        return await _auth.signInWithPopup(GoogleAuthProvider());
      } on FirebaseAuthException catch (e) {
        if (e.code == 'popup-closed-by-user' ||
            e.code == 'cancelled-popup-request') {
          return null;
        }
        rethrow;
      }
    }

    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // dibatalkan user di picker akun

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      // Best-effort: kalau ini gagal, user tetap ter-signout dari Firebase
      // Auth (baris di atas) — cuma next time login Google, picker akun
      // mungkin langsung pilih akun terakhir tanpa nanya ulang.
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
  }

  /// Dipanggil sekali setelah register sukses, untuk bikin dokumen profil
  /// di koleksi `users` (terpisah dari data auth Firebase).
  Future<void> createUserDoc(String uid, Map<String, dynamic> data) {
    return _client.setDocument(FirestorePaths.users, uid, data);
  }

  /// Return null kalau dokumen belum ada (bukan exception) — diteruskan
  /// apa adanya dari FirestoreRestClient.getDocument.
  Future<Map<String, dynamic>?> getUserDoc(String uid) {
    return _client.getDocument(FirestorePaths.users, uid);
  }

  Future<void> updateUserDoc(String uid, Map<String, dynamic> data) {
    return _client.updateFields(FirestorePaths.users, uid, data);
  }
}
