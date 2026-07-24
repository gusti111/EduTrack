import '../core/errors/app_exception.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Stream<String?> get authStateChanges;
  String? get currentUid;
  String? get currentEmail;

  Future<void> login(String email, String password);
  Future<void> register(String email, String password, {String? displayName});
  Future<void> sendPasswordReset(String email);
  Future<void> logout();
  Future<UserModel?> getUserProfile(String uid);
  Future<void> updateDisplayName(String uid, String displayName);
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
  Future<void> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final credential = await _authService.register(email.trim(), password);
      final uid = credential.user!.uid;

      final userModel = UserModel(
        uid: uid,
        email: email.trim(),
        displayName: displayName,
        createdAt: DateTime.now(),
      );
      // Dokumen profil di koleksi `users`, terpisah dari data auth Firebase.
      await _authService.createUserDoc(uid, userModel.toMap());
    } catch (e) {
      throw mapExceptionToFailure(e);
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
      final doc = await _authService.getUserDoc(uid);
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, uid);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> updateDisplayName(String uid, String displayName) async {
    try {
      await _authService.updateUserDoc(uid, {'displayName': displayName});
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }
}
