import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

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

  // Inisialisasi data locale Bahasa Indonesia untuk package `intl` (nama
  // hari/bulan). Dilakukan sekali di sini, sebelum runApp, supaya semua
  // pemakaian DateFormat/TableCalendar dengan locale 'id_ID' di seluruh
  // app (CalendarScreen, StatisticsScreen, dll) aman dipakai tanpa risiko
  // MissingLocaleDataException saat runtime.
  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // MIGRASI: blok `FirebaseFirestore.instance.settings = Settings(...)`
  // yang dulu ada di sini (persistence, webExperimentalForceLongPolling)
  // sudah TIDAK RELEVAN lagi — app ini tidak lagi memakai package
  // `cloud_firestore` untuk operasi data sama sekali, sudah digantikan
  // FirestoreRestClient (HTTP REST biasa, lihat
  // lib/core/network/firestore_rest_client.dart) yang tidak butuh
  // pengaturan koneksi streaming apapun. FirebaseAuth di atas tetap
  // dipakai seperti biasa karena terbukti tidak bermasalah.

  runApp(const App());
}
