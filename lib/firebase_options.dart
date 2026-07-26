import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Hasil generate dari `flutterfire configure`. Aman untuk di-commit
/// (bukan rahasia) — beda dengan .env yang menyimpan config sensitif lain.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk platform ini. '
          'Jalankan `flutterfire configure` untuk menambahkan platform baru '
          '(mis. macOS/Windows/Linux).',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBZ9u9S5ImGe03OyemyOOmfnjBf9lQj3DQ',
    appId: '1:963404057121:ios:1eab4c8b337a6c707bb160',
    messagingSenderId: '963404057121',
    projectId: 'edutrack-e9eb2',
    storageBucket: 'edutrack-e9eb2.firebasestorage.app',
    iosClientId:
        '963404057121-76rbsso0r3mgg63s655uhjeij8pklh0r.apps.googleusercontent.com',
    iosBundleId: 'com.example.eduTrack',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyABHoa2tu8Giq_HRjsmV0_0BBtMkYP8aa8',
    appId: '1:963404057121:android:df5cfa52d63c2dca7bb160',
    messagingSenderId: '963404057121',
    projectId: 'edutrack-e9eb2',
    storageBucket: 'edutrack-e9eb2.firebasestorage.app',
  );

  // Catatan: `measurementId` sengaja DIHAPUS dari hasil generate asli.
  // Kehadirannya bikin Firebase otomatis mencoba inisialisasi Google
  // Analytics (gtag/google-analytics.com) sebagai bagian dari
  // Firebase.initializeApp() di web — kalau request itu diblokir jaringan
  // (banyak kampus/kantor blokir google-analytics.com walau gstatic.com
  // dibiarkan), SELURUH initializeApp() ikut gagal dengan error
  // "[core/not-initialized]", padahal project ini tidak pakai package
  // firebase_analytics sama sekali. Kalau nanti benar-benar mau pakai
  // Analytics, tambahkan package firebase_analytics dulu baru masukkan
  // measurementId ini lagi: 'G-Q977PRKC78'.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyATX-lVzOOeKoS4-_Y7tAlI-CUCGoXp08Q',
    appId: '1:963404057121:web:410b613f488c95bf7bb160',
    messagingSenderId: '963404057121',
    projectId: 'edutrack-e9eb2',
    authDomain: 'edutrack-e9eb2.firebaseapp.com',
    storageBucket: 'edutrack-e9eb2.firebasestorage.app',
  );
}
