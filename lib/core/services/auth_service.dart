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
    return _firestore.collection(FirestorePaths.users).doc(uid).set(data);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) {
    return _firestore.collection(FirestorePaths.users).doc(uid).get();
  }

  Future<void> updateUserDoc(String uid, Map<String, dynamic> data) {
    return _firestore.collection(FirestorePaths.users).doc(uid).update(data);
  }
}
