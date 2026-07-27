import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../app/constants/firestore_paths.dart';
import '../network/firestore_rest_client.dart';

/// MIGRASI: penyimpanan token FCM ke dokumen user (field `fcmTokens`)
/// sebelumnya pakai `FieldValue.arrayUnion`/`arrayRemove` dari
/// cloud_firestore SDK — REST API Firestore biasa tidak punya operasi
/// atomic itu, jadi di sini diakali manual: baca dulu daftar token yang
/// ada, gabung/hapus di sisi client, baru ditulis ulang lewat
/// [FirestoreRestClient.updateFields]. Fungsi ini fire-and-forget dan
/// sudah dibungkus try-catch di pemanggilnya (AuthProvider), jadi
/// kegagalan di sini tidak pernah menghalangi user login/logout.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreRestClient _client = FirestoreRestClient();

  Future<void> initialize() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          'Notification received in foreground: ${message.notification?.title}');
    });
  }

  Future<void> registerTokenForUser(String uid) async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _addTokenToDatabase(uid, token);
      }

      _fcm.onTokenRefresh.listen((newToken) {
        _addTokenToDatabase(uid, newToken);
      });
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  Future<void> unregisterTokenForUser(String uid) async {
    try {
      String? token = await _fcm.getToken();
      if (token == null) return;

      final data = await _client.getDocument(FirestorePaths.users, uid);
      final tokens = _tokensFrom(data)..remove(token);
      await _client.updateFields(
        FirestorePaths.users,
        uid,
        {'fcmTokens': tokens},
      );
    } catch (e) {
      debugPrint('Error unregistering FCM token: $e');
    }
  }

  Future<void> _addTokenToDatabase(String uid, String token) async {
    final data = await _client.getDocument(FirestorePaths.users, uid);
    final tokens = _tokensFrom(data);
    if (!tokens.contains(token)) tokens.add(token);
    await _client.updateFields(
      FirestorePaths.users,
      uid,
      {'fcmTokens': tokens},
    );
  }

  List<String> _tokensFrom(Map<String, dynamic>? data) {
    final raw = data?['fcmTokens'];
    if (raw is List) return raw.whereType<String>().toList();
    return <String>[];
  }
}
