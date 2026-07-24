import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../app/constants/firestore_paths.dart';

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        await _saveTokenToDatabase(uid, token);
      }

      _fcm.onTokenRefresh.listen((newToken) {
        _saveTokenToDatabase(uid, newToken);
      });
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  Future<void> unregisterTokenForUser(String uid) async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _firestore.collection(FirestorePaths.users).doc(uid).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
    } catch (e) {
      debugPrint('Error unregistering FCM token: $e');
    }
  }

  Future<void> _saveTokenToDatabase(String uid, String token) async {
    await _firestore.collection(FirestorePaths.users).doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }
}
