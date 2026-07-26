import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/constants/firestore_paths.dart';

/// Lapisan paling bawah untuk auth: hanya tahu soal FirebaseAuth/Firestore,
/// tidak tahu soal UserModel atau Failure.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Sama seperti di FirestoreService: batas waktu wajar untuk operasi
  // tulis Firestore, supaya kalau SDK macet tanpa exception (kasus nyata
  // yang pernah terjadi terutama di Flutter Web), UI tetap dapat error
  // yang jelas alih-alih tombol "Simpan" berputar selamanya.
  static const Duration _writeTimeout = Duration(seconds: 15);

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

  Future<void> signOut() => _auth.signOut();

  /// Dipanggil sekali setelah register sukses, untuk bikin dokumen profil
  /// di koleksi `users` (terpisah dari data auth Firebase).
  Future<void> createUserDoc(String uid, Map<String, dynamic> data) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .set(data)
        .timeout(_writeTimeout);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .get()
        .timeout(_writeTimeout);
  }

  Future<void> updateUserDoc(String uid, Map<String, dynamic> data) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .update(data)
        .timeout(_writeTimeout);
  }
}
