import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// ⚠️ PLACEHOLDER — file ini WAJIB diganti dengan hasil generate asli.
///
/// Jalankan di root proyek:
///   flutterfire configure
///
/// Itu akan membuat ulang file ini secara otomatis dengan API key & project
/// config yang benar sesuai project Firebase kamu. File hasil generate itu
/// AMAN untuk di-commit (bukan rahasia) — beda dengan .env yang menyimpan
/// config sensitif lain.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions belum dikonfigurasi untuk web. '
        'Jalankan `flutterfire configure`.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBZ9u9S5ImGe03OyemyOOmfnjBf9lQj3DQ',
    appId: '1:963404057121:ios:1eab4c8b337a6c707bb160',
    messagingSenderId: '963404057121',
    projectId: 'edutrack-e9eb2',
    storageBucket: 'edutrack-e9eb2.firebasestorage.app',
    iosBundleId: 'com.example.eduTrack',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyABHoa2tu8Giq_HRjsmV0_0BBtMkYP8aa8',
    appId: '1:963404057121:android:df5cfa52d63c2dca7bb160',
    messagingSenderId: '963404057121',
    projectId: 'edutrack-e9eb2',
    storageBucket: 'edutrack-e9eb2.firebasestorage.app',
  );
}
