import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/failure.dart';
import '../core/services/push_notification_service.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// UI (lewat AuthGate) hanya perlu baca [status] dan [uid] untuk memutuskan
/// mau render layar apa. Aksi login/register/logout expose [isSubmitting]
/// dan [failure] sendiri-sendiri supaya form bisa nunjukin loading/error lokal.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository) {
    _subscription = _repository.authStateChanges.listen((uid) {
      _uid = uid;
      _status =
          uid == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
      notifyListeners();

      if (uid != null) {
        // Fire-and-forget: kegagalan simpan token tidak boleh menghalangi
        // user masuk ke app.
        PushNotificationService.instance.registerTokenForUser(uid);
      }
    });
  }

  final AuthRepository _repository;
  late final StreamSubscription<String?> _subscription;

  AuthStatus _status = AuthStatus.unknown;
  String? _uid;
  bool _isSubmitting = false;
  Failure? _failure;

  AuthStatus get status => _status;
  String? get uid => _uid;
  bool get isSubmitting => _isSubmitting;
  Failure? get failure => _failure;

  Future<bool> login(String email, String password) =>
      _submit(() => _repository.login(email, password));

  Future<bool> register(String email, String password, {String? displayName}) =>
      _submit(() =>
          _repository.register(email, password, displayName: displayName));

  Future<bool> sendPasswordReset(String email) =>
      _submit(() => _repository.sendPasswordReset(email));

  Future<void> logout() => _repository.logout();

  Future<bool> _submit(Future<void> Function() action) async {
    _isSubmitting = true;
    _failure = null;
    notifyListeners();

    try {
      await action();
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _failure = e is Failure ? e : const UnknownFailure();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
