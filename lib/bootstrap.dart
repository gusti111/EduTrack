import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'firebase_options.dart';

/// Menangani semua inisialisasi berat & error handling global,
/// supaya main.dart tetap tipis dan mudah dibaca.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // TODO: kirim ke Crashlytics kalau sudah dipasang.
  };

  // Config sensitif (bukan Firebase key — itu aman di firebase_options.dart)
  // dibaca dari assets/env.txt. Dua alasan sekaligus kenapa bukan ".env":
  // 1) Dev server lokal Flutter Web menganggap file berawalan titik sebagai
  //    hidden file dan menolaknya (500).
  // 2) File TANPA ekstensi sama sekali juga bikin dev server itu gagal
  //    menentukan MIME type-nya dan crash ("Bad state: No element") saat
  //    coba serve lewat `flutter run -d chrome`.
  // ".txt" aman dari dua-duanya. File ini tetap tidak ikut ke-commit
  // (lihat .gitignore).
  await dotenv.load(fileName: 'assets/env.txt');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // PENTING: ini harus jadi sentuhan PERTAMA ke Firestore di seluruh app,
  // sebelum widget App (dan seluruh Provider/Service di dalamnya, termasuk
  // AuthService yang menulis dokumen profil user saat Register) pernah
  // dibuat. Firestore hanya mau menerima `settings =` satu kali, sebelum
  // ada operasi apapun terjadi pada instance itu — kalau terlambat,
  // assignment ini akan diam-diam gagal atau melempar
  // "Firestore has already been started and its settings can no longer
  // be changed."
  //
  // `webExperimentalAutoDetectLongPolling` khusus untuk Flutter Web:
  // Firestore Web memakai koneksi streaming jangka panjang (WebChannel)
  // yang sering diblokir/dipotong oleh jaringan restriktif (proxy kampus,
  // firewall kantor, dll) — persis gejala "loading lama lalu timeout,
  // padahal Auth selalu sukses karena Auth cuma HTTP request biasa".
  // Flag ini membuat SDK otomatis mendeteksi kondisi itu dan pindah ke
  // mode long-polling, tanpa perlu dipaksa manual.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: !kIsWeb,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    webExperimentalAutoDetectLongPolling: kIsWeb ? true : null,
  );

  runApp(const App());
}
